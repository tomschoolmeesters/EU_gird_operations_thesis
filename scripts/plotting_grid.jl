using JSON
using PlotlyJS
using DataFrames

# INSERT HERE THE LINK TO THE GRID MODEL
##############################################
EU_grid = deepcopy(input_data)
##############################################

nodes = [] # vector for the buses
lat = [] # vector for the latitude of the buses
lon = [] # vector for the longitude of the buses
type = [] # to differentiate the bus type (AC or DC)
count_ = 0
for i in 1:length(EU_grid["bus"]) # number of ac buses here
    print(i,"\n")
    if haskey(EU_grid["bus"]["$i"],"lat")
        push!(nodes,EU_grid["bus"]["$i"]["index"])
        push!(lat,EU_grid["bus"]["$i"]["lat"])
        push!(lon,EU_grid["bus"]["$i"]["lon"])
        push!(type,0)
    end
end    
#=
for i in 1:length(EU_grid["busdc"]) # number of dc buses here
    print(i,"\n")
    l = 10000 + i
    if haskey(EU_grid["busdc"]["$l"],"lat")
        push!(nodes,EU_grid["busdc"]["$l"]["index"])
        push!(lat,EU_grid["busdc"]["$l"]["lat"])
        push!(lon,EU_grid["busdc"]["$l"]["lon"])
        push!(type,1)
    end
end     

buses = []
for (b_id,b) in EU_grid["busdc"]
    print(b_id,"\n")
    push!(buses,parse(Int64,b_id))
end
sort(buses)
=#


branches = [] # vector for the branches
lat_fr = [] # vector for the latitude of the fr_buses of the branches
lon_fr = [] # vector for the longitude of the fr_buses of the branches
lat_to = [] # vector for the latitude of the to_buses of the branches
lon_to = [] # vector for the longitude of the to_buses of the branches
bus_fr_ = [] # fr bus
bus_to_ = [] # to bus
rate_a = [] # rating of the line
type_branch = [] # AC or DC
overload = [] # this is the vector that allows to plot different overloading conditions for different branches in the grid 

for i in 1:length(EU_grid["branch"]) # number of AC branches
    print(i,"\n")
    if haskey(EU_grid["branch"],"$i")
        push!(branches,EU_grid["branch"]["$i"]["index"])
        push!(bus_fr_,EU_grid["branch"]["$i"]["f_bus"])
        push!(bus_to_,EU_grid["branch"]["$i"]["t_bus"])
        bus_fr = EU_grid["branch"]["$i"]["f_bus"]
        bus_to = EU_grid["branch"]["$i"]["t_bus"]
        push!(rate_a,abs(EU_grid["branch"]["$i"]["rate_a"]))
        push!(lat_fr,EU_grid["bus"]["$bus_fr"]["lat"])
        push!(lon_fr,EU_grid["bus"]["$bus_fr"]["lon"])
        push!(lat_to,EU_grid["bus"]["$bus_to"]["lat"])
        push!(lon_to,EU_grid["bus"]["$bus_to"]["lon"])
        push!(type_branch,0)
        push!(overload,1.0)
    else
        push!(branches,1)
        push!(bus_fr_,1)
        push!(bus_to_,1)
        bus_fr = 1
        bus_to = 1
        push!(rate_a,1)
        push!(lat_fr,1)
        push!(lon_fr,1)
        push!(lat_to,1)
        push!(lon_to,1)
        push!(type_branch,2)
        push!(overload,1.0)
    end
end

#=
for i in 1:length(EU_grid["branchdc"]) # number of DC branches
    if EU_grid["branchdc"]["$i"]["name"][1:5] != "NSEH-" && EU_grid["branchdc"]["$i"]["name"][1:5] != "DE OF"
        print(EU_grid["branchdc"]["$i"]["name"],"\n")
        push!(branches,EU_grid["branchdc"]["$i"]["index"])
        push!(bus_fr_,EU_grid["branchdc"]["$i"]["fbusdc"])
        push!(bus_to_,EU_grid["branchdc"]["$i"]["tbusdc"])
        bus_fr = EU_grid["branchdc"]["$i"]["fbusdc"]
        bus_to = EU_grid["branchdc"]["$i"]["tbusdc"]
        push!(rate_a,abs(EU_grid["branchdc"]["$i"]["rateA"]))
        push!(lat_fr,EU_grid["busdc"]["$bus_fr"]["lat"])
        push!(lon_fr,EU_grid["busdc"]["$bus_fr"]["lon"])
        push!(lat_to,EU_grid["busdc"]["$bus_to"]["lat"])
        push!(lon_to,EU_grid["busdc"]["$bus_to"]["lon"])
        push!(type_branch,1)
        push!(overload,1.0)
    end
end
=#

# Creating dataframe dictionart
dict_nodes =DataFrames.DataFrame("node"=>nodes,"lat"=>lat,"lon"=>lon, "type"=> type)
map_=DataFrames.DataFrame("from"=>bus_fr_,"to"=>bus_to_,"lat_fr"=>lat_fr,"lon_fr"=>lon_fr,"lat_to"=>lat_to,"lon_to"=>lon_to, "rate" => rate_a, "type" => type_branch, "overload" => overload)
txt_x=1

ac_buses=filter(:type => ==(0), dict_nodes)        
markerAC = PlotlyJS.attr(size=[15*txt_x],
            color="green")


dc_buses=filter(:type => ==(1), dict_nodes)        
markerDC = PlotlyJS.attr(size=[15*txt_x],
            color="red")
           

#AC buses legend
traceAC = [PlotlyJS.scattergeo(;mode="markers",textfont=PlotlyJS.attr(size=10*txt_x),
textposition="top center",text=string(row[:node]),
lat=[row[:lat]],lon=[row[:lon]],
marker=markerAC)  for row in eachrow(ac_buses)]


#DC buses legend
traceDC = [PlotlyJS.scattergeo(;mode="markers",#textfont=PlotlyJS.attr(size=10*txt_x),
textposition="top center",text=string(row[:node][1]),
           lat=[row[:lat]],lon=[row[:lon]],
           marker=markerDC)  for row in eachrow(dc_buses)] 
mode="markers+text"

#DC line display
lineDC = PlotlyJS.attr(width=1*txt_x,color="red")#,dash="dash")
 
#AC line display
lineAC = PlotlyJS.attr(width=1*txt_x,color="navy")#,dash="dash")
 
#AC line legend
trace_AC=[PlotlyJS.scattergeo(;mode="lines",
lon=[row.lon_fr,row.lon_to],
lat=[row.lat_fr,row.lat_to],
opacity = row.overload,
line=lineAC)
for row in eachrow(map_) if (row[:type]==0)]

#DC line display
#lineDC = PlotlyJS.attr(width=1*txt_x,color="red")#,dash="dash")
 
#
#DC line legend
trace_DC=[PlotlyJS.scattergeo(;mode="lines",
lat=[row.lat_fr,row.lat_to],
lon=[row.lon_fr,row.lon_to],
opacity = row.overload,
line=lineDC)
for row in eachrow(map_) if (row[:type]==1)]

#combine plot data   
# Everything             
#trace=vcat(traceAC,trace_AC,traceDC,trace_DC)

# Only branches
trace=vcat(trace_AC,trace_DC)

# Only AC
#trace=vcat(trace_AC)
 
#set map location
geo = PlotlyJS.attr(scope="europe",fitbounds="locations",#lonaxis=attr(range=[40,58], showgrid=true),
#lataxis=attr(range=[-3,15], showgrid=true))
) 
#plot layput
layout = PlotlyJS.Layout(geo=geo,geo_resolution=100, width=1500, height=1500,
showlegend = false, 
#legend = PlotlyJS.attr(x=0,y = 0.95,font=PlotlyJS.attr(size=25*txt_x),bgcolor= "#1C00ff00"),
margin=PlotlyJS.attr(l=0, r=0, t=0, b=0))
#display plot
#PlotlyJS.plot(trace, layout)
PlotlyJS.savefig(PlotlyJS.plot(trace, layout), joinpath(dirname(@__DIR__),"results/Figures/AC_DC_EU_grid_nodal.svg"))
#PlotlyJS.savefig(PlotlyJS.plot(trace, layout), joinpath(folder_results,folder,"Figures_"*"$case","$hour"*".png"))
#savefig(PlotlyJS.plot(trace, layout), ".png")

