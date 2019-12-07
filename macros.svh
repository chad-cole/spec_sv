// Sub-macro #1. Implement the functions "get_type()" and "get_object_type()"
`define object_registry_internal(T,S) \
   typedef Factory#(T) type_id; \
   //typedef Factory#(T,`"S`") type_id; \
   static function type_id get_type(); \
     return type_id::get(); \
   endfunction \
 
// Sub-macro #2. Implement the function "create()"
`define object_create_func(T) \
   function Object create (string name=""); \
     T tmp = new(name); \
     return tmp; \
   endfunction
 
// Sub-macro #3. Implement the function "get_type_name()"
`define object_get_type_name_func(T) \
   const static string type_name = `"T`"; \
   virtual function string get_type_name (); \
     return type_name; \
   endfunction 

`define register(T)\
    `object_registry_internal(T,T)\
    `object_create_func(T)\
    `object_get_type_name_func(T)

`define initialize_field(NAME, TYPE, VALUE) \
    begin\
        if(!this.exists(`"NAME`"))\
            this.``NAME = database_item_field#(TYPE)::type_id::create(`"NAME`"); \
        this.``NAME.set(VALUE);\
        this.add_field(this.``NAME);\
    end
