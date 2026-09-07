library(shiny)
library(DBI)
library(RMySQL)
library(ggplot2)
library(DT)
library(dotenv)

# Load local environment variables when a .env file is available.
env_paths <- c(".env", "../.env")
for (env_path in env_paths) {
  if (file.exists(env_path)) {
    dotenv::load_dot_env(env_path)
    break
  }
}

required_env <- c("MYSQL_DB", "MYSQL_HOST", "MYSQL_USER", "MYSQL_PASSWORD")
missing_env <- required_env[Sys.getenv(required_env) == ""]

if (length(missing_env) > 0) {
  stop(
    paste(
      "Missing required environment variables:",
      paste(missing_env, collapse = ", ")
    )
  )
}

con <- dbConnect(
  RMySQL::MySQL(),
  dbname = Sys.getenv("MYSQL_DB"),
  host = Sys.getenv("MYSQL_HOST"),
  user = Sys.getenv("MYSQL_USER"),
  password = Sys.getenv("MYSQL_PASSWORD")
)

ui <- fluidPage(
  titlePanel("Healthcare Analytics Dashboard"),
  sidebarLayout(
    sidebarPanel(
      selectInput(
        "year",
        "Select Year:",
        choices = c("2008", "2009", "2010"),
        selected = "2008"
      ),
      selectInput(
        "demographic",
        "Select Demographic Filter:",
        choices = c("Sex", "Race_Code"),
        selected = "Sex"
      )
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Inpatient Cost Trends", plotOutput("inpatientCostPlot")),
        tabPanel("Outpatient Claims Distribution", plotOutput("outpatientClaimsPlot")),
        tabPanel("Average Reimbursement", dataTableOutput("reimbursementTable")),
        tabPanel("Average Claim Duration", plotOutput("claimDurationPlot"))
      )
    )
  )
)

server <- function(input, output, session) {

  selected_year <- reactive({
    as.integer(input$year)
  })

  selected_demographic <- reactive({
    match.arg(input$demographic, c("Sex", "Race_Code"))
  })

  inpatientCosts <- reactive({
    demographic <- selected_demographic()
    year <- selected_year()

    query <- sprintf(
      paste0(
        "SELECT %s, SUM(ic.Claim_Payment_Amount) AS Total_Cost ",
        "FROM Inpatient_Claims ic ",
        "JOIN Beneficiaries b ON ic.Beneficiary_ID = b.Beneficiary_ID ",
        "WHERE YEAR(ic.Claim_From_Date) = %d ",
        "GROUP BY %s ",
        "ORDER BY Total_Cost DESC"
      ),
      demographic,
      year,
      demographic
    )

    dbGetQuery(con, query)
  })

  output$inpatientCostPlot <- renderPlot({
    data <- inpatientCosts()
    demographic <- selected_demographic()

    ggplot(
      data,
      aes_string(x = demographic, y = "Total_Cost", fill = demographic)
    ) +
      geom_col(show.legend = FALSE) +
      labs(
        title = paste("Inpatient Costs by", demographic),
        subtitle = paste("Year:", selected_year()),
        x = demographic,
        y = "Total Cost"
      ) +
      theme_minimal()
  })

  outpatientClaims <- reactive({
    year <- selected_year()

    query <- sprintf(
      paste0(
        "SELECT Diagnosis_Code, COUNT(Claim_ID) AS Claim_Count ",
        "FROM Outpatient_Claims ",
        "WHERE YEAR(Claim_From_Date) = %d ",
        "AND Diagnosis_Code IS NOT NULL ",
        "GROUP BY Diagnosis_Code ",
        "ORDER BY Claim_Count DESC ",
        "LIMIT 20"
      ),
      year
    )

    dbGetQuery(con, query)
  })

  output$outpatientClaimsPlot <- renderPlot({
    data <- outpatientClaims()

    ggplot(
      data,
      aes(x = reorder(Diagnosis_Code, Claim_Count), y = Claim_Count)
    ) +
      geom_col() +
      coord_flip() +
      labs(
        title = "Top Outpatient Diagnosis Codes by Claim Count",
        subtitle = paste("Year:", selected_year()),
        x = "Diagnosis Code",
        y = "Number of Claims"
      ) +
      theme_minimal()
  })

  reimbursementRates <- reactive({
    year <- selected_year()

    query <- sprintf(
      paste0(
        "SELECT Claim_Type, AVG(Reimbursement) AS Avg_Reimbursement ",
        "FROM (",
        "SELECT 'Inpatient' AS Claim_Type, Reimburse_IP AS Reimbursement FROM Beneficiaries WHERE Year = %d ",
        "UNION ALL ",
        "SELECT 'Outpatient' AS Claim_Type, Reimburse_OP AS Reimbursement FROM Beneficiaries WHERE Year = %d ",
        "UNION ALL ",
        "SELECT 'Carrier' AS Claim_Type, Reimburse_Carrier AS Reimbursement FROM Beneficiaries WHERE Year = %d",
        ") AS Combined ",
        "GROUP BY Claim_Type"
      ),
      year,
      year,
      year
    )

    dbGetQuery(con, query)
  })

  output$reimbursementTable <- renderDataTable({
    datatable(
      reimbursementRates(),
      rownames = FALSE,
      options = list(pageLength = 10, searching = FALSE)
    )
  })

  claimDuration <- reactive({
    year <- selected_year()

    query <- sprintf(
      paste0(
        "SELECT Claim_Type, AVG(Claim_Duration) AS Avg_Claim_Duration_Days ",
        "FROM (",
        "SELECT 'Inpatient' AS Claim_Type, DATEDIFF(Claim_Through_Date, Claim_From_Date) AS Claim_Duration ",
        "FROM Inpatient_Claims WHERE YEAR(Claim_From_Date) = %d ",
        "UNION ALL ",
        "SELECT 'Outpatient' AS Claim_Type, DATEDIFF(Claim_Through_Date, Claim_From_Date) AS Claim_Duration ",
        "FROM Outpatient_Claims WHERE YEAR(Claim_From_Date) = %d ",
        "UNION ALL ",
        "SELECT 'Carrier' AS Claim_Type, DATEDIFF(Claim_Through_Date, Claim_From_Date) AS Claim_Duration ",
        "FROM Carrier_Claims WHERE YEAR(Claim_From_Date) = %d",
        ") AS Combined ",
        "GROUP BY Claim_Type"
      ),
      year,
      year,
      year
    )

    dbGetQuery(con, query)
  })

  output$claimDurationPlot <- renderPlot({
    data <- claimDuration()

    ggplot(
      data,
      aes(x = Claim_Type, y = Avg_Claim_Duration_Days, fill = Claim_Type)
    ) +
      geom_col(show.legend = FALSE) +
      labs(
        title = "Average Claim Duration",
        subtitle = paste("Year:", selected_year()),
        x = "Claim Type",
        y = "Average Duration (Days)"
      ) +
      theme_minimal()
  })

  session$onSessionEnded(function() {
    if (dbIsValid(con)) {
      dbDisconnect(con)
    }
  })
}

shinyApp(ui = ui, server = server)
