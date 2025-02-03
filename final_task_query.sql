-- Menyiapkan total nett sales per tahun dan nett sales per provinsi dalam satu WITH
WITH TotalNettSales AS (
    SELECT 
        EXTRACT(YEAR FROM t.date) AS tahun,
        SUM(t.price * (1 - t.discount_percentage / 100)) AS total_nett_sales
    FROM `gifted-runner-449409-f2.kimia_farma.final_transaction` t
    WHERE EXTRACT(YEAR FROM t.date) BETWEEN 2020 AND 2023
    GROUP BY tahun
),
NettSalesPerProvinsi AS (
    SELECT 
        c.provinsi,
        SUM(t.price * (1 - t.discount_percentage / 100)) AS total_nett_sales
    FROM `gifted-runner-449409-f2.kimia_farma.final_transaction` t
    JOIN `gifted-runner-449409-f2.kimia_farma.kantor_cabang` c 
        ON t.branch_id = c.branch_id
    WHERE EXTRACT(YEAR FROM t.date) BETWEEN 2020 AND 2023
    GROUP BY c.provinsi
    ORDER BY total_nett_sales DESC
    LIMIT 10  -- Ambil hanya 10 provinsi dengan Nett Sales tertinggi
),
RankedBranches AS (
    SELECT 
        c.branch_name, 
        c.rating AS rating_cabang, 
        t.rating AS rating_transaksi,
        RANK() OVER (ORDER BY c.rating DESC, t.rating ASC) AS ranking
    FROM `gifted-runner-449409-f2.kimia_farma.final_transaction` t
    JOIN `gifted-runner-449409-f2.kimia_farma.kantor_cabang` c 
        ON t.branch_id = c.branch_id
)

-- Mengambil detail transaksi dan menggabungkannya dengan total nett sales serta filter top 5 cabang
SELECT 
    t.transaction_id,
    t.date,
    tn.tahun,
    tn.total_nett_sales,
    c.branch_id,
    rb.branch_name,
    c.kota,
    c.provinsi,
    rb.rating_cabang,
    t.customer_name,
    p.product_id,
    p.product_name,
    t.price AS actual_price,
    t.discount_percentage,

    -- Perhitungan Nett Sales
    t.price * (1 - t.discount_percentage / 100) AS nett_sales,

    -- Perhitungan Persentase Gross Laba
    CASE 
        WHEN t.price <= 50000 THEN 0.10
        WHEN t.price > 50000 AND t.price <= 100000 THEN 0.15
        WHEN t.price > 100000 AND t.price <= 300000 THEN 0.20
        WHEN t.price > 300000 AND t.price <= 500000 THEN 0.25
        ELSE 0.30
    END AS persentase_gross_laba,

    -- Perhitungan Nett Profit
    (t.price * (1 - t.discount_percentage / 100)) * 
    CASE 
        WHEN t.price <= 50000 THEN 0.10
        WHEN t.price > 50000 AND t.price <= 100000 THEN 0.15
        WHEN t.price > 100000 AND t.price <= 300000 THEN 0.20
        WHEN t.price > 300000 AND t.price <= 500000 THEN 0.25
        ELSE 0.30
    END AS nett_profit,

    t.rating AS rating_transaksi

FROM `gifted-runner-449409-f2.kimia_farma.final_transaction` t
JOIN `gifted-runner-449409-f2.kimia_farma.kantor_cabang` c 
    ON t.branch_id = c.branch_id
JOIN `gifted-runner-449409-f2.kimia_farma.product` p
    ON t.product_id = p.product_id
JOIN TotalNettSales tn
    ON EXTRACT(YEAR FROM t.date) = tn.tahun
JOIN RankedBranches rb
    ON c.branch_name = rb.branch_name
WHERE rb.ranking <= 5  -- Ambil hanya Top 5 cabang dengan rating cabang tinggi tetapi rating transaksi rendah

ORDER BY tn.tahun, c.branch_id;
