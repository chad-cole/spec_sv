import spec_pkg::*;

module top;
    //Create some handles for test objects
    spec_database spec_db;
    spec ramp_time;
    spec temp;
    initial begin

        //Create a new Database
        spec_db = new();

        //Create a new Spec
        ramp_time = new("ramp_time");
        $display(ramp_time.str());

        //Add item to database
        spec_db.add_item(ramp_time);

        //Get item from database
        temp = spec_db.get_item("ramp_time");
        
        if(temp != null) begin
            //Add spec limits
            temp.set_limits("0.3",,"0.6");
            
            //Since temp is a shallow copy, these display statements should be
            //equivalent
            $display(temp.str());
            $display(spec_db.get_item("ramp_time").str());

            //Exercise test function with condition on VDD - Should Pass
            void'(temp.test(0.52,"VDD_Slew=3.5"));

            //Exercise test function with condition on VDD - Should Fail
            void'(temp.test(0.25,"VDD=3.5"));

            //Test to_string function for whole database
            $display(spec_db.str());

            //Test loading from CSV file
            spec_db.load_csv("specs.csv");
            $display(spec_db.str());

            //Add a custom field to spec at handle 'temp'
            temp.create_add_generic_field("vcca","3.2");
            $display(temp.get_field("vccb"));
        end else $display("temp is null");
    end
endmodule : top 
