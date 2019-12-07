class FileAndStringTasks;

typedef string array_of_string [];
typedef string queue_of_string [$];

static bit invalid_chars[byte] = '{" ":1'b1,"\n":1'b1,"\t":1'b1};

static function automatic array_of_string tokenize (string in, byte separator = ",");
    automatic int index [$];
    automatic array_of_string out;

    foreach (in[i]) begin
        if (in[i] == separator) begin
            index.push_back(i-1);
            index.push_back(i+1);
        end
    end
    index.push_front(0);
    index.push_back(in.len()-1);

    out = new[index.size()/2];
    foreach (out[i]) 
        out[i] = FileAndStringTasks::strip(in.substr(index[2*i], index[2*i+1]));
    return out;
endfunction : tokenize

static function automatic string strip(string in);
    int i1 = 0, i2 = in.len()-1;
    while( i1 < i2 && FileAndStringTasks::invalid_chars.exists(in[i1])) i1++;
    while( i2 > i1 && FileAndStringTasks::invalid_chars.exists(in[i2])) i2--;
    return in.substr(i1, i2);
endfunction : strip

static function queue_of_string read_lines(string csv_path);
    int fd;
    string line;
    string lines [$];

    fd = $fopen(csv_path, "r");
    if(!fd) begin 
        $display("ERROR: CSV could not be found at path."); 
        $finish;
    end
    while (!$feof(fd)) begin
        void'($fgets(line, fd));
        lines.push_back(line);
    end
    $fclose(fd);
    return lines;
endfunction : read_lines

endclass : FileAndStringTasks

