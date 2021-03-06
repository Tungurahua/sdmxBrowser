## devtools::install_github("rstudio/shinydashboard")
## shiny::runGitHub(repo = "sdmxBrowser", username = "bowerth")

## app.R ##
library(shiny)
library(shinydashboard)
library(RJSDMX)
library(reshape2)
library(ggplot2)

output <- NULL

ui.sdmxBrowser.col <- c("#4F81BD", "#C0504D", "#9BBB59", "#8064A2", "#4BACC6", "#F79646")
ui.sdmxBrowser.year <- c(1970, as.numeric(as.character((format(Sys.time(), "%Y")))) + 2)

## create list with flows by provider
ui.sdmxbrowser_provider <- getProviders()
## remove providers known to have issues
ui.sdmxbrowser_provider <- ui.sdmxbrowser_provider[!ui.sdmxbrowser_provider%in%c("OECD", "OECD_RESTR", "NBB", "ISTAT")]
ui.sdmxbrowser_provider <- ui.sdmxbrowser_provider[!ui.sdmxbrowser_provider%in%c("ILO", "BIS", "WB")]

.sdmxbrowser_dimensions_all <- reactive({
    sdmxbrowser_dimensions_all<- names(getDimensions(input$sdmxbrowser_provider,
                                                     input$sdmxbrowser_flow))
    return(sdmxbrowser_dimensions_all)
})

## flow list
load("data_init/sdmxBrowser.rda")

header <- dashboardHeader(title = "sdmxBrowser")

sidebar <- dashboardSidebar(disable = TRUE,
    sidebarMenu(
      menuItem("Browse Flows", tabName = "browseflows", icon = icon("th"))
      ## ,
      ## menuItem("Widgets", tabName = "widgets", icon = icon("th"))
      )
    )

browseflows.input <- box(
  width = 4,
  title = "Controls",
  wellPanel(
    uiOutput("uisB_query"),
    ## actionButton("sdmxbrowser_querySendButton", "Send query"),
    ## shinysky::actionButton("sdmxbrowser_querySendButton", "Submit Query", styleclass="success",icon = NULL, size = "large", block = TRUE),
    actionButton("sdmxbrowser_querySendButton", "Submit Query")
    ## ,
    ## helpText("Click button to retrieve values")
    ## ,
    ## downloadButton('download_sdmxBrowser', 'Download CSV')
    ),
  wellPanel(
    h5("SDMX Query Builder"),
    uiOutput("uisB_provider"),
    uiOutput("uisB_flow"),
    actionButton("sdmxbrowser_flow_updateButton", "Update Flows"),
    wellPanel(
      uiOutput("uisB_dimensions"),
      uiOutput("uisB_dimensioncodes")
      ),
    sliderInput(inputId = "sdmxbrowser_yearStartEnd",
                label = "Period:",
                min = 1970,
                max = 2015,
                value = c(2000, 2012)
                ,
                sep = ""
                ## pre = NULL,
                ## post = NULL,
                ## format = "#"
                )
    )
  )


browseflows.output <- box(width = 8,
  verbatimTextOutput("summary1")
  ,
  plotOutput("plot1", height = 350)
  ,
  dataTableOutput("table1")
  )

body <- dashboardBody(
    tabItems(
      tabItem(tabName = "browseflows",
              fluidRow(
                ## column(width = 20,
                browseflows.input
                ## )
              ,
                ## column(width = 10,
                browseflows.output
                ## )
                )
              )
      ## ,
      ## tabItem(tabName = "widgets",
      ##         h2("Widgets tab content")
      ##         )
      )
    )

ui <- dashboardPage(
  header,
  sidebar,
  body
  )

server <- function(input, output) {
  set.seed(122)
  histdata <- rnorm(500)

  observe({
    if (is.null(input$sdmxbrowser_flow_updateButton) || input$sdmxbrowser_flow_updateButton == 0) {
        return()
    } else {
        isolate({
            load(file.path("data_init", "sdmxBrowser.rda"))
            ## provider <- "EUROSTAT"
            provider <- input$sdmxbrowser_provider
            flows <- getFlows(provider)
            flows <- sort(names(flows))
            ## flows <- list(flows)
            ## names(flows) <- provider
            ui.sdmxBrowser.flows.list[[provider]] <- flows
            ## length(ui.sdmxBrowser.flows.list[["EUROSTAT"]])
            save(ui.sdmxBrowser.flows.list, file = "data_init/sdmxBrowser.rda")
            print("saved flow information")
        })
    }
})

  output$uisB_provider <- renderUI({
    ui.sdmxbrowser_provider <- getProviders()
    selectInput("sdmxbrowser_provider", "Provider:", ui.sdmxbrowser_provider,
                selected = "EUROSTAT",
                multiple = FALSE)
})

  output$uisB_provider <- renderUI({
    ## ui.sdmxbrowser_provider <- getProviders()
    ## ui.sdmxbrowser_provider
    selectInput("sdmxbrowser_provider", "Provider:", ui.sdmxbrowser_provider,
                ## selected = state_init_list("sdmxbrowser_provider","EUROSTAT", ui.sdmxbrowser_provider),
                # selected = "OECD",
                selected = "EUROSTAT",
                multiple = FALSE)
})

output$uisB_flow <- renderUI({

    sdmxbrowser_provider <- input$sdmxbrowser_provider
    if (input$sdmxbrowser_flow_updateButton != 0) {
        load("data_init/sdmxBrowser.rda")
    }
    ui.sdmxbrowser_flow <- ui.sdmxBrowser.flows.list[[sdmxbrowser_provider]]
    selectInput("sdmxbrowser_flow", "Flow:", c("", ui.sdmxbrowser_flow),
                ## selected = "", 
                selected = "nama_nace64_c",  
                multiple = FALSE)
})
##
.sdmxbrowser_dimensions_all <- reactive({
    sdmxbrowser_dimensions_all<- names(getDimensions(input$sdmxbrowser_provider,
                                                     input$sdmxbrowser_flow))
    return(sdmxbrowser_dimensions_all)
})

output$uisB_dimensions <- renderUI({

    if (input$sdmxbrowser_flow=="") return()

    sdmxbrowser_dimensions_all <- .sdmxbrowser_dimensions_all()
    selectInput("sdmxbrowser_dimensions", "Filter Dimensions:", sdmxbrowser_dimensions_all,
                ## selected = state_multvar("sdmxbrowser_dimensions", sdmxbrowser_dimensions_all),
                selected = sdmxbrowser_dimensions_all,
                multiple = TRUE, selectize = FALSE)
})

.sdmxbrowser_dimensioncodes <- reactive({
    sdmxbrowser_dimensions <- input$sdmxbrowser_dimensions
    sdmxbrowser_dimensioncodes <- as.list(sdmxbrowser_dimensions)
    sdmxbrowser_dimensioncodes <- sapply(sdmxbrowser_dimensioncodes,function(x) NULL)
    names(sdmxbrowser_dimensioncodes) <- sdmxbrowser_dimensions
    return(sdmxbrowser_dimensioncodes)
})

output$uisB_dimensioncodes <- renderUI({
    sdmxbrowser_provider <- input$sdmxbrowser_provider
    sdmxbrowser_flow <- input$sdmxbrowser_flow
    sdmxbrowser_dimensions <- input$sdmxbrowser_dimensions

    if (sdmxbrowser_flow!="") {

        sdmxbrowser_dimensioncodes <- .sdmxbrowser_dimensioncodes()
        command.all <- NULL
        for (d in seq(along = sdmxbrowser_dimensions)) {
            ## get all codes
            sdmxbrowser_dimensioncodes[[d]] <- names(getCodes(sdmxbrowser_provider,
                                                              sdmxbrowser_flow,
                                                              sdmxbrowser_dimensions[d]))

            sdmxbrowser_dimensioncodes[[d]] <- sort(sdmxbrowser_dimensioncodes[[d]])

            command <- paste0('selectInput("sdmxbrowser_dimensioncodes_', d,
                              '", "Select ', sdmxbrowser_dimensions[d],
                              ':", c("',
                              gsub(', ', '", "', toString(sdmxbrowser_dimensioncodes[[d]]))
                              ,
                              '"), selected = "', sdmxbrowser_dimensioncodes[[d]][1], '", multiple = TRUE, selectize = TRUE)')
            command.all <- paste(command.all, command, sep = ",")
        }
        command.all <- sub(",", "", command.all)
        eval(parse(text = paste0('list(', command.all, ')')))

    } else {
        return(h5("Please select data flow and submit query"))
    }

})

output$uisB_query <- renderUI({
    sdmxbrowser_flow <- input$sdmxbrowser_flow
    sdmxbrowser_dimensions <- input$sdmxbrowser_dimensions # selected dimensions

    if (sdmxbrowser_flow!="") {

        sdmxbrowser_dimensioncodes <- .sdmxbrowser_dimensioncodes()
        for (d in seq(along = sdmxbrowser_dimensions)) {
            eval(parse(text = paste0('sdmxbrowser_dimensioncodes[[', d, ']] <- input$sdmxbrowser_dimensioncodes_', d)))
        }
        sdmxbrowser_dimensions_all<- .sdmxbrowser_dimensions_all()
        dimequal <- match(sdmxbrowser_dimensions_all, sdmxbrowser_dimensions)
        query <- sdmxbrowser_flow
        for (d in seq(along = dimequal)) {
            if (is.na(dimequal[d])) {
                query.part <- "*"
            } else {
                query.part <- gsub(", ", "+", toString(sdmxbrowser_dimensioncodes[[dimequal[d]]]))
            }
            query <- paste(query, query.part, sep = ".")
        }
        textInput("sdmxbrowser_query", "SDMX Query:",
                  query)

    } else {
        return(h5("Please select data flow and submit query"))
    }

  })
  yearStart <- reactive({
    as.character(input$sdmxbrowser_yearStartEnd[1])
  })
  yearEnd <- reactive({
    as.character(input$sdmxbrowser_yearStartEnd[2])
  })
  
  output$summary1 <- renderPrint({
    sdmxbrowser_provider = input$sdmxbrowser_provider
    sdmxbrowser_flow = input$sdmxbrowser_flow
    sdmxbrowser_dimensions_all = .sdmxbrowser_dimensions_all()
    sdmxbrowser_query = input$sdmxbrowser_query
    ## yearStart <- as.character(input$sdmxbrowser_yearStartEnd[1])
    ## yearEnd <- as.character(input$sdmxbrowser_yearStartEnd[2])

    ## queryData <- result$queryData

    if (sdmxbrowser_flow=="") return(cat("Please select data flow and submit query"))

    blurb <- paste(paste('Provider =', sdmxbrowser_provider),
                   paste('Flow =', sdmxbrowser_flow),
                   paste('Dimensions =', toString(sdmxbrowser_dimensions_all)),
                   paste('Query =', sdmxbrowser_query),
                   paste('Start =', yearStart()),
                   paste('End =', yearEnd()),
                   ## paste('Frequency =', queryDataFreq()),
                   sep = '\n')

    return(cat(blurb))

  })

  queryData <- reactive({
    if(input$sdmxbrowser_querySendButton == 0) {
      isolate({
        queryData <- getSDMX(input$sdmxbrowser_provider,
                             input$sdmxbrowser_query,
                             start = yearStart(),
                             end = yearEnd())
      })
    } else {
      isolate({
        queryData <- getSDMX(input$sdmxbrowser_provider,
                             input$sdmxbrowser_query,
                             start = yearStart(),
                             end = yearEnd())
      })
    }
    return(queryData)
  })

  queryDataFreq <- reactive({
    frequency(queryData()[[1]])
  })

  queryDataMelt <- reactive({
    queryDataMelt <- as.data.frame(queryData())
    queryDataMelt <- data.frame(time = rownames(queryDataMelt), queryDataMelt)
    queryDataMelt <- suppressWarnings(melt(queryDataMelt, id.vars = "time"))
    return(queryDataMelt)
  })

  output$plot1 <- renderPlot({
    
    if (input$sdmxbrowser_querySendButton==0) return()
    
    sdmxbrowser_flow = input$sdmxbrowser_flow
    sdmxbrowser_query <- input$sdmxbrowser_query
    sdmxbrowser_yearStart <- yearStart()
    sdmxbrowser_yearEnd <- yearEnd()

    queryDataFreq <- queryDataFreq()
    queryDataMelt <- queryDataMelt()

    data.plots <- queryDataMelt

    if (sdmxbrowser_flow=="") return()

    if (queryDataFreq==12) {
        data.plots$time <- as.Date(as.yearmon(data.plots$time, format = "%b %Y"))
    } else if (queryDataFreq==4) {
        data.plots$time <- as.Date(as.yearqtr(data.plots$time))
    } else if (queryDataFreq==1) {
        data.plots$time <- as.Date(paste0(data.plots$time, '-01-01'), format = "%Y-%m-%d")
    }

    ncol <- length(unique(data.plots$variable))
    color.fill <- colorRampPalette(ui.sdmxBrowser.col)(ncol)

    p1 <- ggplot(data = data.plots, aes(x = time, y = value, group = variable)) +
      geom_line(aes(color = variable)) +
        ylab(label = NULL) +
          xlab(label = NULL) +
            scale_colour_manual(values = color.fill) +
              theme_bw() +
                theme(legend.position = "bottom",
                      ## legend.box = "vertical"
                      legend.direction = "vertical"
                      ) ## +
                  ## ggtitle(label = paste(sdmxbrowser_query, "Start:", min(data.plots$time), "End:", max(data.plots$time)))

    ## print(p1)
    return(p1)

  })

  output$table1 <- renderDataTable({

    if (input$sdmxbrowser_querySendButton==0) return(data.frame(INFO = "Please select data flow and submit query"))
    
    sdmxbrowser_dimensions_all = .sdmxbrowser_dimensions_all()
    queryDataMelt <- queryDataMelt()

    data.datatable <- queryDataMelt
    X <- strsplit(as.character(data.datatable$variable), split = "[.]")

    for (d in (seq(along = sdmxbrowser_dimensions_all)+1)) { # first item is flow id, d starting from 2
      data.datatable[[sdmxbrowser_dimensions_all[d-1]]] <- sapply(X, '[[', d)
    }
    data.datatable <- data.datatable[,!colnames(data.datatable)=="variable"]

    return(data.datatable)

  })
    
}

shinyApp(ui, server)

