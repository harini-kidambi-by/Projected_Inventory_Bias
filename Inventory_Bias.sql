-- Tenant  = GSK Production
-- Sample size = top 3000 nodes based on revenuw
-- Period = last 6 months

WITH filter_cte (
	derived_id
	,Revenue
	)
AS (
	SELECT TOP (3000) b.derived_id
		,a.order_quantity * a.unit_price AS 'Revenue'
	FROM [sales_order_line] a
	LEFT JOIN node_inventory b ON a.supplier_item_name = b.customer_item_name
		AND a.ship_from_site_name = b.ship_to_site_name
	WHERE a.need_by_date > Dateadd(MONTH, - 6, Getdate())
		AND a.need_by_date <= Dateadd(MONTH, 0, Getdate())
		AND a.line_status <> 'cancelled'
	ORDER BY (a.order_quantity * a.unit_price) DESC
	)
	,pi_cte (
	node_inventory_derived_id
	,measure_date
	,pi
	)
AS (
	SELECT node_inventory_derived_id
		,measure_date
		,pi
	FROM (
		SELECT cast(node_inventory_derived_id AS CHAR) AS 'node_inventory_derived_id'
			,quantity AS 'pi'
			,cast(measure_date AS DATE) AS 'measure_date'
      -- Latest projected inventory computation is considered
			,rank() OVER ( 
				PARTITION BY node_inventory_derived_id
				,measure_date ORDER BY version_date DESC
				) AS rank_
		FROM node_inventory_projected_inventory
		WHERE node_inventory_derived_id IN (
				SELECT [derived_id]
				FROM filter_cte
				)
			AND measure_date > Dateadd(MONTH, - 6, Getdate()) 
			AND measure_date <= Dateadd(day, 0, Getdate())
		) c
	WHERE rank_ = 1
	)
	,oh_cte (
	node_inventory_derived_id
	,measure_date
	,on_hand
	)
AS (
	SELECT node_inventory_derived_id
		,measure_date
		,on_hand
	FROM (
		SELECT cast(node_inventory_derived_id AS CHAR) AS 'node_inventory_derived_id'
			,sum(quantity) AS 'on_hand' -- aggregated over multiple lot/batch ids
			,cast(measure_date AS DATE) AS 'measure_date'
		FROM node_inventory_on_hand
		WHERE node_inventory_derived_id IN (
				SELECT [derived_id]
				FROM filter_cte
				)
			AND measure_date > Dateadd(Month, - 6, Getdate())
			AND measure_date <= Dateadd(day, 0, Getdate())
		GROUP BY node_inventory_derived_id
			,measure_date
		) d
	)
	,join1_cte (
	node_inventory_derived_id
	,measure_date
	,on_hand
	,pi
	)
AS (
	SELECT COALESCE(a.node_inventory_derived_id, b.node_inventory_derived_id) AS 'node_inventory_derived_id'
		,COALESCE(a.measure_date, b.measure_date) AS measure_date
		,a.on_hand
		,b.pi
	FROM oh_cte a
	FULL OUTER JOIN pi_cte b ON a.node_inventory_derived_id = b.node_inventory_derived_id
		AND a.measure_date = b.measure_date
	)
	,join2_cte (
	node_inventory_derived_id
	,measure_date
	,pi
	,on_hand
	,variance
	,var_pc
	)
AS (
	SELECT a.node_inventory_derived_id
		,a.measure_date
		,a.[pi]
		,a.on_hand
		,(a.on_hand - a.pi) AS 'variance'
		,abs(a.on_hand - a.pi) / nullif(a.pi, 0) AS 'var_pc'
	FROM join1_cte a
	LEFT JOIN filter_cte b ON a.node_inventory_derived_id = b.derived_id
	)
SELECT *
FROM join2_cte
