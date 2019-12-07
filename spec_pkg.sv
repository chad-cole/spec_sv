package spec_pkg;

import database_pkg::*;

class spec extends database_item;

    typedef database_item_field#(real)    real_field;
    typedef database_item_field#(int)     int_field;
    typedef database_item_field#(string)  string_field;

    `register(spec)

    database_item_field#(real) min;
    database_item_field#(real) typ;
    database_item_field#(real) max;
    database_item_field#(real) typ_tol;
    database_item_field#(int)  sf_upload;
    database_item_field#(int)  scm;
    database_item_field#(string) specid;
    database_item_field#(string) vvcm_table;

    function new(string name); 
        super.new(name); 
        `initialize_field(typ_tol, real, 0.1)
        `initialize_field(sf_upload, int, 1'b0);
        `initialize_field(scm, int, 1'b0);
    endfunction
    
    function void set_sf_fields(string specid = "", string vvcm_table = "");
        if(specid != "" && vvcm_table != "") begin
            `initialize_field(sf_upload, int, 1'b1);
            `initialize_field(scm, int, 1'b1);
            `initialize_field(specid, string, specid);
            `initialize_field(vvcm_table, string, vvcm_table);
        end
    endfunction : set_sf_fields
    
    function void set_sf_upload(bit upload);
        `initialize_field(sf_upload, int, upload);
    endfunction : set_sf_upload

    function void set_typ_tol(real tol = 0.1);
        `initialize_field(typ_tol, real, tol)
    endfunction : set_typ_tol

    function void set_limits(string min = "", string typ = "", string max = "");
        if(min != "") `initialize_field(min, real, min.atoreal())
        if(typ != "") `initialize_field(typ, real, typ.atoreal())
        if(max != "") `initialize_field(max, real, max.atoreal())
    endfunction : set_limits

    function string min_spec(); return this.get_field("min"); endfunction
    function string max_spec(); return this.get_field("max"); endfunction
    function string typ_spec(); return this.get_field("typ"); endfunction

    function automatic void create_add_generic_field(string name, string data);
        string_field new_field = string_field::type_id::create(name);
        new_field.set(data);
        this.add_field(new_field);
    endfunction : create_add_generic_field
    
    function automatic bit test(real value, string conditions = "");
        bit passes;
        real min, typ, max, typ_tol;
        string sf, scm;
        begin
            sf  = (this.sf_upload.get() ? "sf" : "");
            scm = (this.scm.get() ? "scm" : "");
            if(this.exists("max") && this.exists("min")) begin //MIN and MAX
                min = this.min.get();
                max = this.max.get();
                passes = (value >= min) && (value <= max);
                $display($sformatf("#%0s#\tva_cb_min_max[%s][%s][%0s]{}=%0.3e,\tlimit_min=%0.3e,\tlimit_max=%0.3e,\tconditions={%0s},\ttime=%g",
                    passes ? "PASS" : "FAIL", sf, scm, this.name, value, min, max, conditions, $realtime));
            end else if (this.exists("min")) begin //MIN only
                min = this.min.get();
                passes = (value >= min);
                $display($sformatf("#%0s#\tva_cb_min[%s][%s][%0s]{}=%0.3e,\tlimit_min=%0.3e,\tconditions={%0s},\ttime=%g",
                    passes ? "PASS" : "FAIL", sf, scm, this.name, value, min, conditions, $realtime));
            end else if (this.exists("max")) begin //MAX only
                max = this.max.get();
                passes = (value <= max);
                $display($sformatf("#%0s#\tva_cb_max[%s][%s][%0s]{}=%0.3e,\tlimit_max=%0.3e,\tconditions={%0s},\ttime=%g",
                    passes ? "PASS" : "FAIL", sf, scm, this.name, value, max, conditions, $realtime));
            end else if (this.exists("typ")) begin //TYP only
                typ = this.typ.get();
                typ_tol = this.typ_tol.get();
                passes = (value >= typ*(1-typ_tol)) && (value <= typ*(1+typ_tol));
                $display($sformatf("#%0s#\tva_cb_typ[%s][%s][%0s]{}=%0.3e,\tlimit_min=%0.3e,\tlimit_max=%0.3e,\tconditions={%0s},\ttime=%g",
                    passes ? "PASS" : "FAIL", sf, scm, this.name, value, typ*(1-typ_tol), typ*(1+typ_tol), conditions, $realtime));
            end else begin
                passes = 1'b0;
                $display($sformatf("#%0s#\tva_cb_no_limits[%s][scm][%0s]{}=%0.3e,\tconditions={%0s},\ttime=%g",
                    passes ? "PASS" : "FAIL", sf, this.name, value, conditions, $realtime));
            end
            return passes;
        end
    endfunction : test

endclass : spec

class spec_database extends database#(spec);

    `register(spec_database)
    
    bit generic_columns [string];

    function new(string name = "spec_database"); this.name = name; endfunction
    
    function spec create_spec(string name, 
            min="", typ="", max="", specid = "", vvcm_table="");
        spec new_spec = super.create_item(name);
        new_spec.set_limits(min, typ, max);
        new_spec.set_sf_fields(specid, vvcm_table);
        return new_spec;
    endfunction

    function automatic spec create_spec_from_line(string header [], string line);
        spec new_spec;
        string tokens [] = FileAndStringTasks::tokenize(line);
        if(tokens[0] != "" && $size(tokens) >= 6) begin
            new_spec = create_spec(tokens[0], tokens[1], tokens[2], tokens[3], tokens[4], tokens[5]);
            for(int i = 6; i < $size(tokens); i++) 
                if(this.generic_columns.exists(header[i]))
                    new_spec.create_add_generic_field(header[i],tokens[i]);
        end
        return new_spec;
    endfunction : create_spec_from_line

    function void include_custom_field(string name);
        this.generic_columns[name] = 1'b1;
    endfunction : include_custom_field
    
    virtual function void load_csv(string csv_path);
        string lines [$] = FileAndStringTasks::read_lines(csv_path);
        string header [] = FileAndStringTasks::tokenize(lines.pop_front());
        foreach(lines[i]) 
            this.add_item(create_spec_from_line(header, lines[i]));
    endfunction : load_csv

endclass : spec_database

endpackage : spec_pkg
