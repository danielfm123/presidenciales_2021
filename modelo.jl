#instala librerias
#using Pkg
#Pkg.add("DataFrames")
#Pkg.add("Feather")
#Pkg.add("JuMP")
#Pkg.add("Ipopt")
#Pkg.add("XLSX")
#Pkg.add("OSQP")
#Pkg.add("COSMO")
#Pkg.add("CSV")


using DataFrames
using XLSX
using Feather
using JuMP
import Ipopt
import OSQP
import COSMO
import CSV


origenes = ["noVoto_pv","boric_pv","kast_pv","provoste_pv","artes_pv","meo_pv","parisi_pv","sichel_pv","nulo_pv","blanco_pv"]

#=
primera_raw = DataFrame(XLSX.readtable("votos1.xlsx","Sheet 1")...)
segunda_raw = DataFrame(XLSX.readtable("votos2.xlsx","Sheet 1")...)
primera_votos_raw = DataFrame(XLSX.readtable("participacion_1ra.xlsx","Sheet1")...)
segunda_votos_raw = DataFrame(XLSX.readtable("participacion_2da.xlsx","Sheet1")...)

#data cleaning participacion
primera_votos = copy(primera_votos_raw)
select!(primera_votos,Not(:votos))

#cleaning primera_raw
primera = copy(primera_raw)
for col in eachcol(primera)
    replace!(col,missing => 0)
end 

for col in names(primera)[8:end]
    rename!(primera, col => col * "_pv")
end

primera[:,"mesa"] =  [replace(x,r" \(Descuadrada\)" => s"") for x in primera[:,"mesa"]]

primera = leftjoin(primera,primera_votos,on = names(primera)[1:7])
primera[:,"noVoto_pv"] = primera[:,"total_mesa"] - 
    sum.(eachrow(primera[:,["boric_pv","kast_pv","provoste_pv","artes_pv","meo_pv","parisi_pv","sichel_pv","nulo_pv","blanco_pv"]]))
select!(primera,Not(:total_mesa))

#data cleaning participacion
segunda_votos = copy(segunda_votos_raw)
select!(segunda_votos,Not(:votos))

#data creaning segunda vuelta
segunda = copy(segunda_raw)
for col in eachcol(segunda)
    replace!(col,missing => 0)
end 

for col in names(segunda)[8:end]
    rename!(segunda, col => col * "_sv")
end

segunda[:,"mesa"] =  [replace(x,r" \(Descuadrada\)" => s"") for x in segunda[:,"mesa"]]
segunda = leftjoin(segunda,segunda_votos,on = names(segunda)[1:7])
segunda[:,"noVoto_sv"] = segunda[:,"total_mesa"] - 
    sum.(eachrow(segunda[:,["boric_sv" , "kast_sv" , "nulo_sv" , "blanco_sv"]]))
select!(segunda,Not(:total_mesa))

dataset = leftjoin(primera,segunda,on = names(segunda)[1:7])
for col in eachcol(dataset)
    replace!(col,missing => 0)
end 

#dataset = DataFrame(XLSX.readtable("dataset.xlsx","Sheet 1")...)

=#

dataset = DataFrame(CSV.File("primera_segunda_H.csv"))


function get_distribution(dataset)
    votos_ant = dataset[:,origenes]
    votos_ant = Matrix(votos_ant)

    #model = Model(COSMO.Optimizer)
    #model = Model(OSQP.Optimizer)
    model = Model(Ipopt.Optimizer)
    #set_optimizer_attribute(model, "max_cpu_time", 60.0)
    #set_optimizer_attribute(model, "print_level", 2)

    @variable(model, delta_boric[1:size(votos_ant,2)] >= 0)
    @variable(model, delta_kast[1:size(votos_ant,2)] >= 0)
    @variable(model, delta_nulos[1:size(votos_ant,2)] >= 0)
    @variable(model, delta_blancos[1:size(votos_ant,2)] >= 0)
    @variable(model, delta_no[1:size(votos_ant,2)] >= 0)


    @objective(model, Min,  
        sum([x*x for x in (votos_ant * delta_boric - dataset.boric_sv)]) +
        sum([x*x for x in (votos_ant * delta_kast - dataset.kast_sv)]) +
        sum([x*x for x in (votos_ant * delta_nulos - dataset.nulo_sv)]) +
        sum([x*x for x in (votos_ant * delta_blancos - dataset.blanco_sv)]) +
        sum([x*x for x in (votos_ant * delta_no - dataset.noVoto_sv)]) 
    )

    @constraint(model, delta_boric .+ delta_kast .+ delta_nulos .+ delta_blancos .+ delta_no .== 1)

    optimize!(model)

    percent = DataFrame(
        origen = origenes,
        delta_boric = [value(x) for x in delta_boric],
        delta_kast = [value(x) for x in delta_kast],
        delta_nulos = [value(x) for x in delta_nulos],
        delta_blancos = [value(x) for x in delta_blancos],
        delta_no = [value(x) for x in delta_no]
        )
    return percent
end

distribution = get_distribution(dataset)
show(distribution, allrows=true)

function to_totals(distribution,dataset)
    votos_ant = dataset[:,origenes]
    votos_ant = Matrix(votos_ant)

    totals = distribution[:,2:end] .* sum(votos_ant,dims = 1)'
    totals.origen = origenes
    return totals
end

total = to_totals(distribution,dataset)
show(total,allrows=true)

#por distrito
comp = DataFrame()
comp_tot = DataFrame()
for r in unique(dataset.distrito)
    print(r)
    sub_dataset = dataset[dataset.distrito .== r,:]
    distribution = get_distribution(sub_dataset)

    totals = to_totals(distribution,sub_dataset)

    totals.distrito .= r
    distribution.distrito .= r
    append!(comp,distribution)
    append!(comp_tot,totals)
end

CSV.write("distrito.csv",comp)
CSV.write("distrito_tot.csv",comp_tot)

#por com_clust
comp = DataFrame()
comp_tot = DataFrame()
for r in unique(dataset.com_clust)
    print(r)
    sub_dataset = dataset[dataset.com_clust .== r,:]
    distribution = get_distribution(sub_dataset)

    totals = to_totals(distribution,sub_dataset)

    totals.com_clust .= r
    distribution.com_clust .= r
    append!(comp,distribution)
    append!(comp_tot,totals)
end

CSV.write("com_clust.csv",comp)
CSV.write("com_clust_tot.csv",comp_tot)