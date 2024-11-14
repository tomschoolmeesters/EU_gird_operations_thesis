###################
### ANALYSE OPF ###
###################

function Analyse_generator(g,start_hour,planning_year) # generator index g, start hour and planning year (2025,2030,2040)
    
    #Get information about gen
    type = nodal_input["gen"]["$g"]["type_tyndp"]
    zone = nodal_input["gen"]["$g"]["zone"]
    bus = nodal_input["gen"]["$g"]["gen_bus"]
    pmax = nodal_input["gen"]["$g"]["pmax"] #MW
    start_date = hour_to_date(planning_year, start_hour)
    end_date = hour_to_date(planning_year, start_hour+number_of_hours-1)

    println("--------------------------------")
    println("Generator index: ",g)
    println("Generator type: ",type)
    println("Generator zone: ",zone)
    println("Generator bus: ",bus)
    println("Theoretical maximum power:", pmax," MW")
    println("Analysed period: vanaf ",start_date," tot ",end_date)
    println("--------------------------------")

    #Determine produced energy profile
    production = []
    for i in start_hour:(start_hour+number_of_hours-1)
        
        if nodal_result["$i"]["objective"] !== nothing
            push!(production,nodal_result["$i"]["solution"]["gen"]["$g"]["pg"])
        else
            push!(production,0.0001) #0.0001 so I can highlight the infeasible time periods
        end
    end

    P1 = plot(production,label="Prodcuction")
    title!("Production profile of generator $g")
    xlabel!("Time [h]")
    ylabel!("Power [MW]")

    time = 1:length(production)
    highlight_indices = findall(x -> x == 0.0001, production)
    scatter!(time[highlight_indices], production[highlight_indices], label="Infeasible", color=:red, marker=:circle)

    if !(nodal_input["gen"]["$g"]["type_tyndp"] in ["Offshore wind","Onshore Wins","Solar PV"])
        display(P1)
    end
    
    #Calculate curtailment 
        #If Offshore Wind
    if nodal_input["gen"]["$g"]["type_tyndp"] == "Offshore Wind"
        gen_type = "wind_offshore"
        Curtailment,Uncurtailed = RES_curtailment_WO(g,gen_type,nodal_result, nodal_input, timeseries_data,start_hour)
        
        plot!(Uncurtailed, label="uncurtailed_energy")
        display(P1)
        
        P2 = plot(Curtailment*100,label = "Curtailment")
        title!("Curtailment of generator $g")
        xlabel!("Time [h]")
        ylabel!("Curtailment [%]")
        display(P2)

        #Print the moments at which the curtailment is higher than 50%
        high_curt = findall(x -> x>0.5,Curtailment)
        high_curt = high_curt .+ (start_hour - 1)
        high_curt_dates = []
        for hour in high_curt
            push!(high_curt_dates,hour_to_date(planning_year,hour))
        end
        println("At the following dates, curtailment is above 50%:")
        for date in high_curt_dates
            println(date)
        end
        println("--------------------------------")

        #If Onshore Wind
    elseif nodal_input["gen"]["$g"]["type_tyndp"] == "Onshore Wind"
        gen_type = "wind_onshore"
        Curtailment,Uncurtailed = RES_curtailment_WO(g,gen_type,nodal_result, nodal_input, timeseries_data,start_hour)
        
        plot!(Uncurtailed, label="uncurtailed_energy")
        display(P1)
        
        P2 = plot(Curtailment*100,label = "Curtailment")
        title!("Curtailment of generator $g")
        xlabel!("Time [h]")
        ylabel!("Curtailment [%]")
        display(P2)

        #Print the moments at which the curtailment is higher than 50%
        high_curt = findall(x -> x>0.5,Curtailment)
        high_curt = high_curt .+ (start_hour - 1)
        high_curt_dates = []
        for hour in high_curt
            push!(high_curt_dates,hour_to_date(planning_year,hour))
        end
        println("At the following dates, curtailment is above 50%:")
        for date in high_curt_dates
            println(date)
        end
        println("--------------------------------")

        #If Solar PV
    elseif nodal_input["gen"]["$g"]["type_tyndp"] == "Solar PV"
        gen_type = "solar_pv"
        Curtailment,Uncurtailed = RES_curtailment_WO(g,gen_type,nodal_result, nodal_input, timeseries_data,start_hour)
        plot!(Uncurtailed,label = "Uncurtailed energy")
        
        
        display(P1)
        P2 = plot(Curtailment*100,label = "Curtailment")
        title!("Curtailment of generator $g")
        xlabel!("Time [h]")
        ylabel!("Curtailment [%]")
        display(P2)

        #Print the moments at which the curtailment is higher than 50%
        high_curt = findall(x -> x>0.5,Curtailment)
        high_curt = high_curt .+ (start_hour - 1)
        high_curt_dates = []
        for hour in high_curt
            push!(high_curt_dates,hour_to_date(planning_year,hour))
        end
        println("At the following dates, curtailment is above 50%:")
        for date in high_curt_dates
            println(date)
        end
        println("--------------------------------")

    end
end


function Analyse_bus(n,start_hour,planning_year)

    #Get information about bus
    zone = nodal_input["bus"]["$n"]["zone"]
    start_date = hour_to_date(planning_year, start_hour)
    end_date = hour_to_date(planning_year, start_hour+number_of_hours-1)

    println("--------------------------------")
    println("Bus zone: ",zone)
    println("Analysed period: vanaf ",start_date," tot ",end_date)
    println("--------------------------------")

    #Determine demand at bus
    demand = []
    for i in start_hour:(start_hour+number_of_hours-1)
        load_index = collect(filter(l -> nodal_input["load"][l]["load_bus"] == n, keys(nodal_input["load"])))
        if length(load_index) == 1
            LF = timeseries_data["demand"][zone][i]
            demand_at_bus = nodal_input["load"][load_index[1]]["pmax"]*LF #in MW
            push!(demand,demand_at_bus)
        end
    end
    P1 = plot(demand,label="Demand")
    title!("Demand profile at bus $n ($zone)")
    xlabel!("Time [h]")
    ylabel!("Power [MW]")
    display(P1)

    #Determine producing generators
    gen_list = []
    for hour in keys(nodal_result)
        if nodal_result["$hour"]["objective"] !== nothing
            for g in keys(nodal_result["$hour"]["solution"]["gen"])
                if nodal_input["gen"]["$g"]["gen_bus"] == n &&
                    !(g in gen_list) #nodal_result["$hour"]["solution"]["gen"]["$g"]["pg"] !== 0.0 && 

                    push!(gen_list,g)
                end
            end
        end
    end

    if length(gen_list) == 0
        println("There are no generators at this bus")
    else

        println("These generators are available at this bus:")
        gen_list = sort(gen_list)
        for g in gen_list
            production = []
            for i in start_hour:(start_hour+number_of_hours-1)
                if nodal_result["$i"]["objective"] !== nothing
                    push!(production,nodal_result["$i"]["solution"]["gen"]["$g"]["pg"])
                else
                    push!(production,0)
                end
            end
            average_power = mean(production)
            maximum_power = maximum(production)
            println("Generator ",g,": ",nodal_input["gen"]["$g"]["type_tyndp"])
            println("    --> with average power= ",average_power)
            println("    --> with maximum power= ",maximum_power)
    
        end
    end
    println("--------------------------------")

    #Get information about flows around that bus
    from_branches = []
    to_branches = []
    for branch in keys(nodal_input["branch"])
        if nodal_input["branch"]["$branch"]["f_bus"] == n
            push!(from_branches,branch)
        elseif nodal_input["branch"]["$branch"]["t_bus"] == n
            push!(to_branches,branch)
        end
    end
    from_branches = sort(from_branches)
    to_branches = sort(to_branches)
    println("This are the branches connected to bus ",n)
    for b in from_branches
        println("Branch ",b,": From bus ",nodal_input["branch"]["$b"]["f_bus"], " ---> To bus ",nodal_input["branch"]["$b"]["t_bus"])
    end
    for b in to_branches
        println("Branch ",b,": From bus ",nodal_input["branch"]["$b"]["f_bus"], " ---> To bus ",nodal_input["branch"]["$b"]["t_bus"])
    end

    Flows = Dict()
    for i in start_hour:(start_hour+number_of_hours-1)
        for b in from_branches
            
            if !haskey(Flows, b)
                # Maak een nieuwe lege lijst voor de branch als deze nog niet bestaat
                Flows[b] = []
            end
            # Voeg de power flow voor dit uur toe aan de lijst van de generator
            if nodal_result["$i"]["objective"] !== nothing
                push!(Flows[b], nodal_result["$i"]["solution"]["branch"]["$b"]["pf"]*100)
            else
                push!(Flows[b],0)
            end
        end
        for b in to_branches
            
            if !haskey(Flows, b)
                # Maak een nieuwe lege lijst voor de branch als deze nog niet bestaat
                Flows[b] = []
            end
            # Voeg de power flow voor dit uur toe aan de lijst van de generator
            if nodal_result["$i"]["objective"] !== nothing
                push!(Flows[b], nodal_result["$i"]["solution"]["branch"]["$b"]["pt"]*100)
            else
                push!(Flows[b],0)
            end
        end
    end

    total_flows_per_timestep = zeros(number_of_hours)
    P3 = plot()
    for b in keys(Flows)
        total_flows_per_timestep .+= Flows[b]
        plot!(Flows[b],label = "Branch $b")
    end
    title!("Active power withdrawn at $n ($zone)")
    xlabel!("Time [h]")
    ylabel!("Power [MW]")
    display(P3)

    P4 = plot()
    plot!(total_flows_per_timestep)
    title!("Sum of the active power flows at bus $n")
    xlabel!("Time [h]")
    ylabel!("Power [MW]")
    display(P4)

end

##############################################
#### LOAD ZONAL TYNDP SCENARIO DATA ##########
##############################################
scenario = "GA2030"
climate_year = "1984"

zonal_result, zonal_input, scenario_data = _EUGO.load_results(scenario, climate_year,"zonal") # Import zonal results

print("ALL ZONAL FILES LOADED", "\n")
print("----------------------","\n")

##############################################
#### LOAD NODAL TYNDP SCENARIO DATA ##########
##############################################
#Run this to load the right simulation scenario

scenario = "GA2030"
climate_year = "1984"
nodal_result, nodal_input, timeseries_data = _EUGO.load_results(scenario, climate_year,"nodal") # Import nodal results

print("ALL NODAL FILES LOADED", "\n")
print("----------------------","\n")

