library(dplyr)
library(plotly)
library("shiny")
library("ggplot2")
library("reshape2")
library("styler")
library("lintr")
library("rsconnect")
library("sp")
library("ggiraph")
library("colormap")

####Intro
suicide <- read.csv("data/master.csv", stringsAsFactors = FALSE)

overview_analysis <- suicide %>%
  group_by(country) %>%
  summarize(
    sum(suicides_no)
  )
overview <- plot_ly(overview_analysis,
                    x = ~ country, y = ~ `sum(suicides_no)`, type = "bar",
                    marker = list(color = "pink")
) %>%
  layout(
    title = "The total number of people who commit suicide from 1985 to 2016
    worldwide",
    xaxis = list(title = "Country"), yaxis = list(title = "Number of People")
  )

####Rita
######bar chart########
#get general data for the bar chart about age group
generalAge <- suicide[c(2, 3, 4, 5)]

#get the function that choose age for the bar chart
ageFunction <- function(inputAge) {
  ageGroup <- generalAge[generalAge$age == inputAge, ]
  
  #get the suicide number of that age group for 30 years 
  ageSum <- ageGroup%>%
    group_by(year, sex)  %>% 
    summarise(
      suicides_no = sum(suicides_no))
  
  #create the bar chart by age and have both sex
  age <-  ggplot(data = ageSum) +
    aes(x=year, y=`suicides_no`, fill=factor(sex))+
    geom_bar(stat="identity",position="dodge")+
    xlab("Year")+ ylab("Suicide total number")
  
  age
}


###### map #####

#get general the data for the world map
general <- suicide[c(1, 2, 3, 5)]

# get the world map
map_world <- map_data("world")

#the function for filter the sex
mapData <- function(inputSex, inputYear) {
  sexData <- function(inputSex) {
    s <-  general %>% filter(sex == inputSex)
  }
  
  sInput <- sexData(inputSex)
  
  #the function for choose year   
  yearData <- function(inputYear) {
    yearNum <- sInput %>% group_by(country, year = inputYear) %>% 
      summarise(
        suicideSum = sum(suicides_no))
  }
  
  mapDf <- yearData(inputYear)
  
  #find the different name and correct it
  mapsNames <- unique(unname(unlist(map_data("world")["region"])))
  dataNames <- mapDf$country
  setdiff(x = dataNames, y = mapsNames)
  names(mapDf)[names(mapDf) == "United Kingdom"] <- "UK"
  names(mapDf)[names(mapDf) == "United States"] <- "USA"
  names(mapDf)[names(mapDf) == "Republic of Korea"] <- "South Korea"
  names(mapDf)[names(mapDf) == "Russian Federation"] <- "Russia"
  names(mapDf)[names(mapDf) == "Antigua and Barbuda"] <- "Antigua"
  names(mapDf)[names(mapDf) == "Cabo Verde" ] <- "Cape Verde"
  names(mapDf)[names(mapDf) == "Macau" ] <- "China"
  names(mapDf)[names(mapDf) == "Saint Vincent and Grenadines" ] <- "Saint Vincent"
  names(mapDf)[names(mapDf) == "Trinidad and Tobago" ] <- "Trinidad"
  
  # combine the chart
  map_world_join <- left_join(map_world, mapDf, by = c("region" = "country"))
  #View(map.world)
  #View(map.world_join)
  map_world_join <- map_world_join %>% mutate(fill_flg = ifelse(is.na(rank),F,T))
  #View(map.world_join)
  df_country_points <- data.frame(country = mapDf$country ,stringsAsFactors = F)
  #glimpse(df.country_points)
  
  #create the map
  #interactive
  g <- ggplot(map_world_join) +
    geom_polygon_interactive(
      color='GRAY',
      aes(long, lat, group=group, fill=suicideSum,
          tooltip = paste(region, "<br/>", suicideSum))
    ) +
    #hrbrthemes::theme_ipsum() +
    colormap::scale_fill_colormap(
      colormap=colormap::colormaps$greens, reverse = T) +
    labs(title='The Suicide Number Around World', subtitle='number of people',
         caption='Source: Suicide Data')
  #widgetframe::frameWidget(ggiraph(code = print(g)))
}  