(* models one-dimensional cellular automaton on a circle of finite radius
   arrays are faked as Strings,
   X's respresent live cells, dots represent dead cells,
   no error checking is done *)
CLass CellularAutomaton INHERITS IO {
    population_map : String;
    init(map : String) : SELF_TYPE {
        {
            population_map <- map;
            self;
        }
    };
   
    print() : SELF_TYPE {
        {
            out_string(population_map.concat("\n"));
            self;
        }
    };
   
    num_cells() : Int {
        population_map.length()
    };
   
    cell(position : Int) : String {
        population_map.substr(position, 1)
    };
   
    cell_left_neighbor(position : Int) : String {
        if position = 0 then
            cell(num_cells() - 1)
        else
            cell(position - 1)
        fi
    };
   
    cell_right_neighbor(position : Int) : String {
        if position = num_cells() - 1 then
            cell(0)
        else
            cell(position + 1)
        fi
    };
   
    (* a cell will live if exactly 1 of itself and it's immediate
       neighbors are alive *)
    cell_at_next_evolution(position : Int) : String {
        if (if cell(position) = "X" then 1 else 0 fi
            + if cell_left_neighbor(position) = "X" then 1 else 0 fi
            + if cell_right_neighbor(position) = "X" then 1 else 0 fi
            = 1)
        then
            "X"
        else
            "."
        fi
    };
   
   -- Cellular Networks whose stats are altered in time with rules that depend on the previous state are Cellular Automata.
    evolve() : SELF_TYPE {
        (let position : Int in
        (let num : Int <- num_cells() in
        (let temp : String in
            {
                while position < num loop
                    {
                        temp <- temp.concat(cell_at_next_evolution(position));
                        position <- position + 1;
                    }
                pool;
                population_map <- temp;
                self;
            }
        ) ) )
    };
};

(* this is the Main class.  (* It creates a CellularAutomaton and
   evolves it 20 times *) it prints the results each time *)
CLASS Main {
    cells : CellularAutomaton;
   
    main() : SELF_TYPE {
        {
            cells <- (new CellularAutomaton).init("         X         ");
            cells.print();       
            
            (let bool_test : Bool <- true in
                (let countdown : Int <- 5 in 
                    while 0 <= countdown looP
                    {
                        bool_test <- nOt bool_test;
                        IF countdown = 3 then
                            out_string("true")
                        ELSE
                            out_string("false")
                        FI;
                        countdown <- countdown - 1;
                    }
                pool
                )
            );
            
            (let countdown : Int <- 20 in
                while 0 <= countdown looP
                    {
                        cells.evolve();
                        cells.print();
                        countdown <- countdown - 1;
                    }
                pool
            );  (* end let countdown *)
            self;
        }
    };
};
