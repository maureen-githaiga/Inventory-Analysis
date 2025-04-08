USE modelcars;


SELECT 
	TOP 10 *
FROM products;

SELECT 
	TOP 10 *
FROM orders;

---time period of the orders
SELECT 
	MIN(orderDate) AS first_order_date, 
    MAX(orderDate) AS last_order_date
FROM orders;

---how many product lines are there
SELECT 
	DISTINCT productLine
FROM products;

--checking Inventory Distribution

---how many warehouses are there
SELECT *
FROM warehouses
ORDER BY warehousePctCap DESC;

---how many different products in the current inventory
SELECT 
	COUNT(p.productCode) AS "count of type of products"
FROM products p;

---productlines per warehouse
SELECT 
	w.warehouseName,
	p.productLine
FROM products p
INNER JOIN warehouses w
ON w.warehouseCode = p.warehouseCode
GROUP BY p.productLine,w.warehouseName
ORDER BY w.warehouseName;

---inventory per warehouse
SELECT 
	w.warehouseName,
	SUM(p.quantityInStock) AS "Total Stock"
FROM products p
INNER JOIN warehouses w
ON w.warehouseCode = p.warehouseCode
GROUP BY w.warehouseName
ORDER BY "Total Stock" DESC ;


---total stock of each product in each warehouse
SELECT 
	p.productName,
	w.warehouseName,
	p.productLine, 
	SUM(p.quantityInStock)AS "Total Stock"
FROM products p
INNER JOIN warehouses w
ON w.warehouseCode = p.warehouseCode
GROUP BY p.productName,p.productLine,w.warehouseName
ORDER BY "Total Stock" DESC;

---are there products stored in multiple warehouses?
SELECT 
	p.productName,
	w.warehouseName,
	COUNT(DISTINCT w.warehouseName) AS "warehouse count"
FROM products p
INNER JOIN warehouses w
ON w.warehouseCode = p.warehouseCode
GROUP BY p.productName,w.warehouseName
HAVING COUNT(DISTINCT w.warehouseName)>1;

---inventory to sales comparison (stock and orders)
SELECT  
	COALESCE(w.warehouseName,'Grand Total') AS "Warehouse",
	CASE 
		WHEN p.productLine IS NULL AND w.warehouseName IS NOT NULL 
		THEN CONCAT( 'Total For',' ',w.warehouseName)
		ELSE p.productLine
	END AS "productLine",
	COALESCE(SUM(p.quantityInStock),0)AS "Total Stock", 
	COALESCE(SUM(o.quantityOrdered),0)AS "Orders"
FROM products p
INNER JOIN warehouses w
ON w.warehouseCode = p.warehouseCode
LEFT JOIN orderdetails o
ON o.productCode  = p.productCode
GROUP BY ROLLUP( w.warehouseName,p.productLine)
ORDER BY w.warehouseName DESC; 

------ stock and sales comparison per products
SELECT 
    p.productCode,
    p.productName,
    p.quantityInStock,
    COALESCE(SUM(od.quantityOrdered), 0) AS totalSales
FROM products p
LEFT JOIN orderdetails od ON p.productCode = od.productCode
GROUP BY p.productCode, p.productName, p.quantityInStock
ORDER BY totalSales DESC;


---identifying products that are not moving (have been in stock but never appeared in orders)
SELECT 
	p.productName,
	w.warehouseName
FROM products p
LEFT JOIN orderdetails o
ON p.productCode = o.productCode
INNER JOIN warehouses w
ON w.warehouseCode = p.warehouseCode
WHERE o.productCode IS NULL
GROUP BY w.warehouseName,p.productName;

---comparing the active vs dormant stock in the east warehouse
SELECT 
    w.warehouseName,
	SUM(p.quantityInStock) AS total_stock,
	SUM(CASE WHEN o.productCode IS NULL THEN p.quantityInStock ELSE 0 END) AS dormant_stock,
    FORMAT((SUM(CASE WHEN o.productCode IS NULL THEN p.quantityInStock ELSE 0 END) * 100.0) / SUM(p.quantityInStock),'N') AS dormant_stock_pct,
    SUM(CASE WHEN o.productCode IS NULL THEN 0 ELSE p.quantityInStock END) AS projected_stock_after_removal
FROM products p
LEFT JOIN orderdetails o ON p.productCode = o.productCode
INNER JOIN warehouses w ON p.warehouseCode = w.warehouseCode
WHERE w.warehouseName = 'East'
GROUP BY w.warehouseName;


----warehouse capacity vs stock
WITH warehousestock AS (
	SELECT 
	warehouseName, 
	warehousePctCap, 
	SUM(quantityInStock) AS totalStock
FROM warehouses w
JOIN products p ON w.warehouseCode = p.warehouseCode
GROUP BY warehouseName, warehousePctCap
)
SELECT 
    ws.warehouseName, 
    ws.warehousePctCap, 
    ws.totalStock,
    FORMAT((ws.totalStock / (ws.warehousePctCap / 100.0)), 'n2') AS fullStockCapacity, 
    FORMAT((ws.totalStock / (ws.warehousePctCap / 100.0)) - ws.totalStock, 'n2') AS remainingCapacity
FROM WarehouseStock ws
ORDER BY ws.warehousePctCap DESC;



---in which warehouses are shipments not shipped within 24hrs
WITH shippingtimeanalysis AS(
	SELECT
			w.warehouseName,
			DATEDIFF(HOUR, o.orderDate, o.shippedDate) AS time_to_ship,
			CASE
				WHEN DATEDIFF(HOUR, o.orderDate, o.shippedDate)<=24 THEN 'Shipped within 24 hrs'
				ELSE 'Shipped after 24 hrs'
			END AS shipping_efficiency
		FROM orders o
		INNER JOIN orderdetails od ON od.orderNumber = o.orderNumber
		INNER JOIN products p ON p.productCode = od.productCode
		INNER JOIN warehouses w ON p.warehouseCode = w.warehouseCode
)
SELECT 
	warehouseName,
	SUM(CASE WHEN shipping_efficiency = 'Shipped within 24 hrs' THEN 1 ELSE 0 END) AS shipped_within_24hrs,
    SUM(CASE WHEN shipping_efficiency = 'Shipped after 24 hrs' THEN 1 ELSE 0 END) AS shipped_after_24hrs
FROM shippingtimeanalysis
GROUP BY warehouseName
ORDER BY shipped_within_24hrs DESC;

---checking if there were any delayed orders
WITH delayed_shippments AS (
    SELECT 
        w.warehouseName,
        o.orderNumber,
        DATEDIFF(HOUR,o.requiredDate,o.shippedDate) AS pastrequireddate
    FROM orders o
    INNER JOIN orderdetails od ON o.orderNumber = od.orderNumber
    INNER JOIN products p ON od.productCode = p.productCode
    INNER JOIN warehouses w ON p.warehouseCode = w.warehouseCode
    WHERE o.shippedDate IS NOT NULL
)
SELECT 
    warehouseName,
    COUNT(DISTINCT orderNumber) AS lateOrdersCount
FROM delayed_shippments
WHERE pastrequireddate > 0
GROUP BY warehouseName;

---how many different product scales are there
SELECT
	DISTINCT productScale
	FROM products;

-------the warehouse absorption capacity analysis by analysing both the product scale and the warehouse capacity 
WITH WarehouseCapacity AS (
	SELECT 
		w.warehouseName, 
		w.warehousePctCap, 
		SUM(p.quantityInStock) AS totalStock,
		SUM(CASE WHEN o.productCode IS NULL THEN p.quantityInStock ELSE 0 END) AS dormantStock,
		ROUND(SUM(p.quantityInStock) - SUM(CASE WHEN o.productCode IS NULL THEN p.quantityInStock ELSE 0 END), 2) AS activeStock,
		ROUND(SUM(p.quantityInStock) / (w.warehousePctCap / 100), 2) AS estimatedFullCapacity
	FROM warehouses w
	INNER JOIN products p ON w.warehouseCode = p.warehouseCode
	LEFT JOIN orderdetails o ON p.productCode = o.productCode
	GROUP BY w.warehouseName, w.warehousePctCap
),

ScaleDistribution AS (
    SELECT 
        w.warehouseName,
        SUM(CASE WHEN p.productScale IN ('1:10', '1:12', '1:18') THEN p.quantityInStock ELSE 0 END) AS largeScaleStock,
        SUM(CASE WHEN p.productScale IN ('1:24', '1:32', '1:50') THEN p.quantityInStock ELSE 0 END) AS mediumScaleStock,
        SUM(CASE WHEN p.productScale IN ('1:700', '1:72') THEN p.quantityInStock ELSE 0 END) AS smallScaleStock
    FROM warehouses w
    INNER JOIN products p ON w.warehouseCode = p.warehouseCode
    GROUP BY w.warehouseName
)

SELECT 
    wc1.warehouseName AS sourceWarehouse,
    wc1.totalStock AS sourceActiveStock,
    wc2.warehouseName AS targetWarehouse,
    wc2.totalStock AS targetActiveStock,
    CAST((wc2.estimatedFullCapacity - wc2.totalStock )AS DECIMAL(10, 2)) AS availableSpace,
    CASE
        WHEN (wc2.estimatedFullCapacity - wc2.activeStock) >= wc1.activeStock 
             AND sd1.largeScaleStock <= sd2.largeScaleStock
             AND sd1.mediumScaleStock <= sd2.mediumScaleStock
             AND sd1.smallScaleStock <= sd2.smallScaleStock
        THEN 'Can Absorb'
        ELSE 'Cannot Absorb'
    END AS absorptionStatus
FROM WarehouseCapacity wc1
INNER JOIN WarehouseCapacity wc2 
ON wc1.warehouseName <> wc2.warehouseName
INNER JOIN ScaleDistribution sd1 ON wc1.warehouseName = sd1.warehouseName
INNER JOIN ScaleDistribution sd2 ON wc2.warehouseName = sd2.warehouseName
ORDER BY wc1.warehouseName, wc2.warehouseName;

