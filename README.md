# Inventory Analysis for Mint Classics Company
This repository contains an **inventory analysis** for **Mint Classics Company**, a retailer specializing in classic model cars and vehicles. The company is evaluating the potential to close one of their storage facilities.
The goal is to provide data-driven recommendations for optimizing inventory re-distribution, identifying dormant stock, and ensuring timely service to customers.

## Problem Overview
Mint Classics operates with several warehouses that hold a wide range of products. These warehouses have varying stock levels and capacities. Some stock has remained dormant, meaning it hasn't been sold for the entire period.


Key questions addressed in this analysis:

- **Which warehouse has the highest stock and capacity?
- **Can stock from one warehouse be absorbed by another warehouse?
- **Warehouse Capacity Utilization**: How can we assess the capacity utilization of each warehouse and ensure that storage space is used efficiently?
- **How do inventory counts relate to sales figures, and do they seem appropriate?

## Goal

The primary objective of this analysis is to provide data-driven recommendations for reorganizing the company’s inventory. Specifically, the analysis focuses on:
- Evaluating warehouse capacity and identifying opportunities to free up space.
- Identifying dormant stock and proposing solutions for better inventory management.
- Recommending whether stock from one warehouse can be absorbed by another.
- Assessing the alignment of inventory levels with sales data.
## Solution Approach

The solution is divided into several steps:

1. **Data Collection and Preprocessing**:
   - Data includes product, order, customer, employee, and warehouse details.
   - The data was cleaned and structured for analysis, with a focus on inventory, warehouse capacity, and sales.

2. **Warehouse Capacity Analysis**:
   - Calculated the total stock of each warehouse and compared it to the warehouse's available capacity.
   - Identified dormant stock by determining products that haven't been ordered for the entire period.

3. **Stock Redistribution Analysis**:
   - Evaluated if a warehouse could absorb stock from another, based on available space and matching product scales (large, medium, small).
   - Considered both active and dormant stock in the analysis.

4. **Sales and Inventory Efficiency**:
   - Analyzed the relationship between sales figures and inventory levels to determine if the current inventory counts are appropriate.
   - Assessed the efficiency of each warehouse based on the number of orders fulfilled.

5. **Shipping Efficiency**:
   - Analyzed how quickly each warehouse is able to ship products, assessing whether they meet the 24-hour shipping standard.

## Conclusion

Key findings from the analysis:
- **Dormant Stock**: A significant portion of the stock in some warehouses, particularly the East warehouse, is dormant, representing inefficiency in space utilization.
- **Warehouse Capacity**: Some warehouses, such as the East and West warehouses, have significant unused capacity that could be leveraged to accommodate more stock.
- **Absorption Potential**: The East warehouse has the capacity to absorb stock from other warehouses based on both space and product scale distribution.
- **Sales vs. Inventory**: There is a mismatch between inventory levels and sales in some warehouses, suggesting that inactive stock could be redistributed or removed.

## Tools and Technologies

- **SQL Server**: The primary database system used for storing and querying inventory and order data.
- **T-SQL**: Structured Query Language (T-SQL) was used to write the queries for analyzing the warehouse and inventory data.

