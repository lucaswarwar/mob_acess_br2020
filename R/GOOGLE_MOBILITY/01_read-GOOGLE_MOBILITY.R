#
# initial config----------------
#

rm(list=ls())
gc(reset = T)
library(XLConnect)
library(gganimate)  # install.packages("gganimate")
library(ggrepel)
source("R/PNS/0_loadpackages.R",local = TRUE)
`%nin%` = Negate(`%in%`)

# generate cities geometries from geobr
# cities <- geobr::read_municipality()
# readr::write_rds(cities,"figures/GOOGLE/read_municipality_data.rds")

# dir.create("figures/GOOGLE/")
# dir.create("data-raw/GOOGLE")

#
# name columns function-----
#
toupper_noaccent <- function(i){
  stringi::stri_trans_general(i,id = "Latin-ASCII") %>% 
    toupper() %>% stringr::str_replace_all("-"," ")  %>% 
    stringr::str_remove_all("'")
}

ls_initial_list <- c("google","activities","%nin%","toupper_noaccent")
# first manipulation

statebr <- geobr::read_state() %>% data.table::setDT()
statebr[,name_state := toupper_noaccent(name_state)]

google <- data.table::fread("data-raw/GOOGLE/Global_Mobility_Report.csv")
google <- google[country_region %in% "Brazil",]
google[,sub_region_1_fix := toupper_noaccent(sub_region_1) %>% 
         stringr::str_remove_all("STATE OF ")]
google[sub_region_1_fix %in% "FEDERAL DISTRICT",sub_region_1_fix := "DISTRITO FEDERAL"]
google[,date_fix := as.POSIXct(date,tz = "America/Bahia")]
google[,year_month := format(date_fix,"%m/%Y")]
google[,day_month := format(date_fix,"%d/%m")]
google[,day_month_id := .GRP,by = date_fix]
google[,sub_region_2_fix := toupper_noaccent(sub_region_2)]
google[statebr,on = c('sub_region_1_fix' = 'name_state'), state_abrev := i.abbrev_state]
google[,name_muni := paste0(sub_region_2_fix,"-",state_abrev)]

activities <- c("retail_and_recreation","grocery_and_pharmacy",
                "parks","transit_stations","workplaces","residential")
local_categories <- c('Varejo e lazer','Mercados e farmácias',
                      'Parques','Estações de transporte público',
                      'Locais de trabalho','Residencial')
description <- c('Tendências de mobilidade de lugares como restaurantes, cafés, \n shopping centers, parques temáticos, museus, bibliotecas e cinemas.',
                 'Tendências de mobilidade de lugares como mercados, armazéns de \n alimentos, feiras, lojas especializadas em alimentos, drogarias e farmácias.',
                 'Tendências de mobilidade de lugares como parques locais e nacionais, \n praias públicas, marinas, parques para cães, praças e jardins públicos.',
                 'Tendências de mobilidade de lugares como terminais de transporte público,\n tipo estações de metrô, ônibus e trem',
                 'Tendências de mobilidade de locais de trabalho',
                 'Tendências de mobilidade de áreas residenciais')
lista <- ls()[ls() %nin% c(ls_initial_list,"ls_initial_list")]
rm(list = lista)

#
# check names-------------
#
google$sub_region_1 %>% unique()
google$sub_region_2 %>% unique()
google$sub_region_2 %>% uniqueN()
google$metro_area %>% unique()
google$iso_3166_2_code %>% unique()
google$census_fips_code %>% unique()
google$date %>% unique()
google$state_abrev %>% unique()

break()
# 
# general graph-------------
#

google1 <- data.table::melt(data = google,
                            id.vars = c('date_fix','day_month_id','state_abrev','sub_region_2'),
                            measure.vars =  list('change' = c('retail_and_recreation_percent_change_from_baseline',
                                                              'grocery_and_pharmacy_percent_change_from_baseline',
                                                              'parks_percent_change_from_baseline',
                                                              'transit_stations_percent_change_from_baseline',
                                                              'workplaces_percent_change_from_baseline',
                                                              'residential_percent_change_from_baseline')))
label_x <- c("15/02","01/03","01/04","01/05","01/06","01/07","01/08")
break_x <- google[day_month %in% label_x,unique(day_month_id)]
limits_x <- c(min(google1$day_month_id),max(google1$day_month_id))

activities

for(i in 1:length(activities)){ # i = 1
  
  message(activities[i])
  # i = 1
  google2 <- data.table::copy(google1)[variable %like% activities[i] & 
                                         sub_region_2 %in% "" & 
                                         state_abrev %nin% "" & 
                                         !is.na(state_abrev),]
  # orderuf
  
  orderuf <- google2[data.table::between(date_fix,"2020-03-15","2020-08-01"),
                     lapply(.SD,sum),
                     .SDcols = 'value',by = state_abrev]
  setorder(orderuf,value)
  orderuf <- orderuf$state_abrev
  google2[,state_abrev := factor(state_abrev,orderuf)]
  
  plot1 <- ggplot(data = google2, aes(x = day_month_id,y = state_abrev)) + 
    geom_tile(aes(fill = value),colour = "white") +
    viridis::scale_fill_viridis(option = "A",direction = -1) +  
    scale_x_continuous(breaks = break_x,
                       labels = label_x) +
    labs(title = local_categories[i],
         subtitle = description[i],
         x = NULL, y = "Estados",
         fill = "Mudança em \nrelação ao \nperíodo base") +
    theme_bw() +
    theme(legend.position = 'right',
          axis.text.x = element_text(angle = 0, hjust = 0,size=8),
          axis.text.y = element_text(angle = 0, hjust = 1,size=8),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank()) + 
    coord_cartesian(xlim = limits_x, expand = FALSE)
  
  
  #
  # boxplot
  #
  avg_df <- google2[,lapply(.SD,mean), .SDcols = 'value', by = day_month_id]
  avg_df[,frollmean7 := data.table::frollmean(value,n = 7)]
  
  plot2 <- ggplot() + 
    geom_boxplot(data = google2, aes(x = day_month_id, y = value,
                                     group = day_month_id, fill = value)) + 
    geom_line(data = avg_df,aes(x = day_month_id, y = frollmean7),color = 'red') +
    labs(x = NULL, 
         y = "Mudança em relação \n ao período base",
         caption = 'Fonte: Google COVID-19 Community Mobility Reports') + 
    scale_x_continuous(breaks = break_x,
                       labels = label_x) + 
    theme_bw() +
    theme(axis.text.x = element_text(angle = 0, hjust = 0,size=8),
          axis.text.y = element_text(angle = 0, hjust = 1,size=8),
          #panel.grid.major = element_blank(),
          panel.grid.minor = element_blank())
  
  pf <- plot1 / plot2
  
  ggsave(filename = paste0("figures/GOOGLE/",activities[i],".png"),
         width = 23.7, height = 17.6, units = "cm")
  
}

# clean up unusefull files

lista <- ls()[ls() %nin% c(ls_initial_list,"ls_initial_list")]
rm(list = lista)

#
# cities analysis-----
#
cities <- readr::read_rds("figures/GOOGLE/read_municipality_data.rds") %>% data.table::setDT()
cities[,name_muni := paste0(toupper_noaccent(name_muni),"-",abbrev_state)]

google1 <- data.table::copy(google)[name_muni %in% cities$name_muni,]
google1[cities,on = 'name_muni',geometry := i.geom]

google2 <- data.table::copy(google1)[name_muni %in% "VERA CRUZ-SP",] 
google2
google2 <- sf::st_as_sf(google2)
plot(google2['residential_percent_change_from_baseline'])
uniqueN(google1$sub_region_2_fix)
head(google1,4)
google1 <- data.table::melt(data = google,
                            id.vars = c('date_fix','day_month_id','state_abrev','sub_region_2'),
                            measure.vars =  list('change' = c('retail_and_recreation_percent_change_from_baseline',
                                                              'grocery_and_pharmacy_percent_change_from_baseline',
                                                              'parks_percent_change_from_baseline',
                                                              'transit_stations_percent_change_from_baseline',
                                                              'workplaces_percent_change_from_baseline',
                                                              'residential_percent_change_from_baseline')))


