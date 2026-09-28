# HR Attrition & Cost Dashboard

An interactive Power BI dashboard analyzing employee attrition patterns and quantifying the financial impact of turnover across departments, tenure bands, and demographic groups.

## Table of Contents
- [Project Overview](#project-overview)
- [Dataset](#dataset)
- [Data Cleaning & Transformation](#data-cleaning--transformation)
- [Data Modeling](#data-modeling)
- [DAX Measures](#dax-measures)
- [Dashboard Design](#dashboard-design)
- [Dashboard Breakdown](#dashboard-breakdown)
- [Key Insight](#key-insight)
- [Tools Used](#tools-used)
- [How to View](#how-to-view)

## Project Overview

Employee attrition is one of the most expensive problems an organization can face — not just in recruitment costs, but in lost productivity, training investment, and institutional knowledge. This dashboard was built to answer a practical business question: **where is attrition concentrated, and what is it actually costing the company?**

This project is the capstone of a self-directed Power BI learning phase, bringing together data transformation (Power Query), data modeling, DAX measures, and dashboard UX principles into a single end-to-end build — following on from an earlier SQL project analyzing e-commerce trends.

## Dataset

The data used is the **IBM HR Analytics Employee Attrition dataset**, sourced from Kaggle. It is a widely used, anonymized HR dataset containing employee-level records including demographics, job role, department, tenure, overtime status, and attrition outcome (whether the employee left the company).

*(Add the direct Kaggle link here once you're ready to publish, e.g. `[Dataset link](https://www.kaggle.com/...)`.)*

## Data Cleaning & Transformation

All transformation was done in **Power Query** before loading the data into the model:

- **Renamed columns** for clarity and consistency, so measures and visuals reference intuitive names rather than raw dataset headers
- **Fixed data types** — corrected fields imported as text/general into their proper types (numeric, date, categorical) so aggregations and DAX calculations would evaluate correctly
- **Created calculated columns**, including grouping raw tenure values into readable **Tenure Bands** used throughout the report, and deriving the fields needed to support the Department, Overtime, and Gender breakdowns

*(Optional: paste your exact M code or column logic here for extra technical detail once you're back in the file.)*

## Data Modeling

The report uses a single-table model built directly from the cleaned dataset, with calculated columns (e.g. Tenure Band) added at the model layer to support grouping in visuals without needing separate lookup tables.

*(If you used a star schema, multiple related tables, or Row-Level Security, add that detail here.)*

## DAX Measures

Custom DAX measures power the core KPIs rather than relying on default column aggregations:

- **Attrition Rate** — Attrition Count divided by Total Employees, using `DIVIDE()` to safely handle any zero-denominator edge cases
- **Avg Cost Per Departure** — a custom measure estimating the average financial impact per employee exit
- Supporting measures driving the dynamic breakdowns by Department, Overtime, Tenure Band, and Gender

```dax
Attrition Rate = DIVIDE([Attrition Count], [Total Employees], 0)
```

*(Add your actual Avg Cost Per Departure formula and any other measures here — this is often the most impressive section for recruiters, since it shows DAX fluency beyond basic SUM/COUNT.)*

## Dashboard Design

Layout follows core dashboard UX principles: a clear headline visual (Attrition Rate and Attrition Count sized prominently at the top), consistent alignment and grouping of related visuals, and deliberate whitespace so the report reads top-to-bottom without clutter. Sidebar slicers (Department, Overtime) let viewers filter the entire page interactively rather than reading static numbers.

## Dashboard Breakdown

**Top-level KPIs:**
- **Total Employees:** 1.47K
- **Attrition Count:** 237
- **Attrition Rate:** 16.12%
- **Avg Cost Per Departure:** $43.08K

**Visual breakdowns:**
- **By Department** — compares attrition volume across Human Resources, Research & Development, and Sales, highlighting which department is losing the most staff
- **By Overtime** — splits attrition between employees who regularly work overtime and those who don't, surfacing whether overtime correlates with higher turnover
- **By Tenure Band** — segments attrition by how long employees stayed before leaving, useful for spotting whether turnover is concentrated in new hires or long-tenured staff
- **By Gender** — shows attrition distribution by gender for demographic context

**Filters:** Department and Overtime slicers in the sidebar apply across the whole page, allowing interactive drill-down into any segment.

## Key Insight

*(This is the most important section for readers — add 2-3 sentences here once you're looking at the dashboard again. For example: which department has the highest attrition rate, whether overtime employees leave more often, and which tenure band is most at risk. This is where you demonstrate the "so what" of the analysis, not just the numbers.)*

## Tools Used

- **Power BI Desktop** — data modeling, DAX measures, and report/visual design
- **Power Query (M)** — data cleaning and transformation
- **DAX** — custom measures for attrition rate, cost calculations, and dynamic breakdowns

## How to View

The `.pbix` file is included in this repository. To explore it interactively:
1. Download [Power BI Desktop](https://powerbi.microsoft.com/desktop/) (free)
2. Open the `.pbix` file
3. Use the Department and Overtime slicers on the left to explore attrition across segments

*(A screen recording or GIF of the dashboard in action, embedded here, makes the project accessible to anyone without Power BI installed — worth adding if you get the chance. Note: Power BI Service publishing isn't required for this — GitHub + a recording is enough for a portfolio piece.)*
