virtual class Object;
    pure virtual function Object create(string name = "");
endclass

class object_proxy#(type OBJ=int) extends Object;
    virtual function Object create(string name = "");
        OBJ subtype = new(name);
        return subtype;
    endfunction
endclass

class Factory#(type BASE=Object);
    Object obj;
    virtual function Object create_obj(string name = "");
        //delegate creation to subtype itself
        create_obj = obj.create(name);
    endfunction

    //Singleton 
    local static Factory#(BASE) factory;
    protected function new(); endfunction
    static function Factory#(BASE) get();
        if(factory == null) begin
            object_proxy#(BASE) obj_p = new;
            factory = new;
            factory.obj = obj_p;
        end
        return factory;
    endfunction

    //Configure subtype
    static function void set_object(Object obj);
        Factory#(BASE) f = get();
        f.obj = obj;
    endfunction

    static function BASE create(string name = "");
        Factory#(BASE) f = get();
        $cast(create, f.create_obj(name));
    endfunction
endclass
