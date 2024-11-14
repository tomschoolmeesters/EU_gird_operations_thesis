

### DATE ###
# Function to determine the dates corresponding with the given hour (1-8760)

using Dates
function hour_to_date(jaar, uur)
    # Controleer of het uur binnen het bereik valt
    if uur < 1 || uur >= 8761
        println("The specified hour must be between 1 and 8760.")
        return
    end

    # Startdatum van het jaar
    startdatum = DateTime(jaar, 1, 1, 0, 0)  # 1 januari om 00:00 uur

    # Bereken de huidige datum en tijd door uren toe te voegen aan de startdatum
    huidige_datumtijd = startdatum + Hour(uur-1)
    
    # Haal de dag, maand, jaar en uur op
    dag = day(huidige_datumtijd)
    maand = month(huidige_datumtijd)
    jaar = year(huidige_datumtijd)
    uur_van_de_dag = hour(huidige_datumtijd)
    
    # Geef de datum en tijd terug als een string
    return "Datum: $dag/$maand/$jaar, Uur: $uur_van_de_dag:00"
end

### GET RES CURTAILMENT ###
# Calculate the amount of RES (wind, solar) energy which is curtailed, 
# Given the generator index g, the generator type: ["Solar PV", "Offshore Wind", "Onshore Wind"], the input data set, the timeseries dataset and the starting hour of the simulation

function RES_curtailment_WO(g,gen_type,result, input, timeseries,start_hour)
    # Create an empty vector to save curtailmentvalues per generator
    RES_Curtailment = zeros(number_of_hours)
    Uncurtailed = zeros(number_of_hours)

    # Iterate over every hour of the simulation
    for i in start_hour:(start_hour+number_of_hours-1)

        # Itereer over elke generator in de oplossing voor dit uur
        if result["$i"]["objective"] !== nothing
    
            if "$g" in keys(result["$i"]["solution"]["gen"])
                            
                # Verkrijg de nodale ID en de benodigde energiewaarden

                zone = input["gen"]["$g"]["zone"]
                CF = timeseries["$gen_type"][zone][i]

                uncurtailed_energy = CF*input["gen"]["$g"]["pmax"] # in MW
                energy_delivered = result["$i"]["solution"]["gen"]["$g"]["pg"] # in MW

                # Calculate the curtailment
                if uncurtailed_energy == 0.0 #Or if CF is equal to zero 
                    curtailment = 0
                else
                    curtailment = (uncurtailed_energy - energy_delivered) / uncurtailed_energy
                end

                # Add values to the corresponding vector
                Uncurtailed[i] = uncurtailed_energy  #Vector with uncuratailed energy for every timestep of generator g
                RES_Curtailment[i] = curtailment #Vector with curtailment value for every timestep of generator g

                
            else
                println("Generator not in result")
            end

        else
            RES_Curtailment[i] = 1
            
            if i-1 == 0
                Uncurtailed[i] =0
            else
                Uncurtailed[i] = Uncurtailed[i-1] #This has to be improved if the infeasibilities remain since now I creat some flat profiles
            end
        end
    end
    return RES_Curtailment,Uncurtailed
end

### CONGESTION INDEX ###
# Compute the congestion index and plot it given the optimization result you want to analyse

function Congestion_index(result)
    Congestion_index_values=Dict()
    for i in keys(result)
        if result["$i"]["objective"] !== nothing
            lambda=[]
            for bus in keys(result["$i"]["solution"]["bus"])
                push!(lambda,result["$i"]["solution"]["bus"]["$bus"]["lam_kcl_r"])
            end
            N = length(result["$i"]["solution"]["bus"])
            lambda_average = sum(lambda)/N
            
            i_c = sum(abs.(lambda.-lambda_average))/(N*abs(lambda_average))
            Congestion_index_values[i] = i_c
        end
        
    end
    return Congestion_index_values

end

function plot_Congestion_index(result)
    Congestion_index_values = Congestion_index(result)
    sorted_keys = sort(collect(keys(Congestion_index_values)), by=x -> parse(Int, x))
    sorted_values = [Congestion_index_values[k] for k in sorted_keys]

    plot(sorted_keys,sorted_values)
    ylabel!("Congestion Index Value")
end



### SATURATION INDEX ###
# Function to calculate the saturation index

function Saturation_index(result,input)
    Saturation_index_values = Dict()
    for i in keys(result)
        if result["$i"]["objective"] !== nothing
            branch = collect(keys(result["$i"]["solution"]["branch"]))
            sum_power_flow = sum(abs(result["$i"]["solution"]["branch"]["$b"]["pt"]) for b in branch) #MW, Active power withdrawn at the to bus
            sum_rated_power = sum(input["branch"]["$b"]["rate_a"] for b in branch) #MVA, Long term thermal line rating
            Saturation_index_values[i] = sum_power_flow/sum_rated_power
        end
    end
    return Saturation_index_values
end

function plot_Saturation_index(result,input)
    Saturation_index_values = Saturation_index(result,input)
    sorted_keys = sort(collect(keys(Saturation_index_values)), by=x -> parse(Int, x))
    sorted_values = [Saturation_index_values[k] for k in sorted_keys]

    plot(sorted_keys,sorted_values)
    ylabel!("Saturation Index Value")
end
