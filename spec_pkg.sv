package spec_pkg;

import database_pkg::*;

class spec extends database_item;

    typedef database_item_field#(real)    real_field;
    typedef database_item_field#(int)     int_field;
    typedef database_item_field#(string)  string_field;

    `register(spec)

    real_field min;
    real_field typ;
    real_field max;
    real_field typ_tol; //Allowable tolerance on typical spec, defaults to +/- 10%
    
    //Informational Fields
    //  alternate_id can be used to link aliased name in other database
    //  source_table_name can be used to cite specification document
    string_field alternate_id;
    string_field source_table_name;

    function new(string name); 
        super.new(name); 
        `initialize_field(typ_tol, real, 0.1)
    endfunction
    
    //alternate_id can be used to link aliased name in other database
    function void set_info_fields(string alternate_id = "", string source_table_name = "");
        if(alternate_id != "" && source_table_name != "") begin
            `initialize_field(alternate_id, string, alternate_id);
            `initialize_field(source_table_name, string, source_table_name);
        end
    endfunction : set_info_fields
    
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
        begin
            if(this.exists("max") && this.exists("min")) begin //MIN and MAX
                min = this.min.get();
                max = this.max.get();
                passes = (value >= min) && (value <= max);
            end else if (this.exists("min")) begin //MIN only
                min = this.min.get();
                passes = (value >= min);
            end else if (this.exists("max")) begin //MAX only
                max = this.max.get();
                passes = (value <= max);
            end else if (this.exists("typ")) begin //TYP only
                typ = this.typ.get();
                typ_tol = this.typ_tol.get();
                passes = (value >= typ*(1-typ_tol)) && (value <= typ*(1+typ_tol));
            end else begin
                passes = 1'b0;
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
            min="", typ="", max="", alternate_id = "", source_table_name="");
        spec new_spec = super.create_item(name);
        new_spec.set_limits(min, typ, max);
        new_spec.set_info_fields(alternate_id, source_table_name);
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
