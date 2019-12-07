virtual class base_field extends Object;
    string name;
    pure virtual function Object create(string name = "");
    pure virtual function string get_name();
    pure virtual function string str();
    pure virtual function string get_type_name();
endclass

class database_item_field#(type T = string) extends base_field;

    `register(database_item_field#(T))
    T data;

    function new(string name); this.name = name; endfunction

    virtual function string get_name();
        return this.name;
    endfunction
    
    virtual function void set(T data);
        this.data = data;
    endfunction
    
    virtual function T get();
        return this.data;
    endfunction
    
    virtual function string str();
        string out;
        case($typename(T))
            "string" : out = $sformatf("%0s",this.data);
            "real"   : out = $sformatf("%0.3e",this.data);
            "int"    : out = $sformatf("%0d",this.data);
        endcase
        return out;
    endfunction

endclass : database_item_field

class database_item#(type T = base_field) extends base_field;

    `register(database_item#(T))

    T fields [string];

    function new(string name = ""); this.name = name; endfunction : new 
    
    function void add_field(T field);
        if(field != null) this.fields[field.get_name()] = field;
    endfunction : add_field
    
    function void delete_field(string name);
        if(this.fields.exists(name)) this.fields.delete(name);
    endfunction : delete_field

    function bit exists(string name);
        return this.fields.exists(name);
    endfunction : exists
    
    function string get_name(); return this.name; endfunction
    
    function string get_field(string name); 
        if(this.exists(name)) return this.fields[name].str(); 
        else return "";
    endfunction
    
    virtual function string str();
        string out = $sformatf("{[name:%s]",this.name);
        foreach (fields[i])
            out = {out, "[", i ,":", fields[i].str(), "]"};
        out = {out, "}"};
        return out;
    endfunction : str

endclass : database_item

class database#(type T = database_item) extends base_field;
    
    `register(database#(T))

    T items [string];

    function new(string name = "database"); this.name = name; endfunction
    
    function string get_name(); return this.name; endfunction

    function void add_item(T item);
        if(item != null) items[item.name] = item;
    endfunction : add_item

    virtual function T create_item(string name = "");
        create_item = T::type_id::create(name);
    endfunction : create_item

    function T get_item(string name);
        T item;
        if(items.exists(name)) item = items[name];
        else item = null;
        return item;
    endfunction : get_item
    
    virtual function string str();
        string out = $sformatf("{[name:%s]",this.name);
        foreach (items[i])
            out = {out, "\n [", i ,":", items[i].str(), "]"};
        out = {out, "\n}"};
        return out;
    endfunction : str

endclass : database
