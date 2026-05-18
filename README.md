# Customer Segmentation and Product Preference Analysis

## Project Overview

This dbt project analyzes customer purchasing behavior using customer, order, item, and product data. The main goal is to segment customers based on **purchase frequency** and **total product value**, then analyze which product types are preferred by each customer segment.

The main business question is:

> **How do product preferences differ across customer segments based on purchase frequency and total product value?**

This analysis helps the business understand customer behavior, identify valuable customer groups, and design targeted marketing strategies.

---

## Business Motivation

Customers have different purchasing behaviors. Some customers order frequently and generate high value, while others order less often but may still purchase expensive products. Treating every customer the same can make marketing less effective.

By creating customer segments, the business can answer questions such as:

- Which customers are high-value and frequent buyers?
- Which customers spend a lot but order less often?
- Which customer groups should receive loyalty rewards?
- Which customer groups should receive promotions or re-engagement campaigns?
- Which product types are preferred by each customer segment?

---

## Data Sources

The project uses the following raw source tables:

| Source Table | Description |
|---|---|
| `raw_customers` | Customer information |
| `raw_orders` | Order-level transaction data |
| `raw_items` | Item-level products purchased in each order |
| `raw_products` | Product information, including product type and price |
| `raw_stores` | Store information |
| `raw_supplies` | Supply information |

---

## Project Structure

The dbt project follows a layered structure:

```text
sources
  ↓
staging models
  ↓
marts models
```

### Staging Layer

The staging layer cleans and standardizes raw data. These models rename columns, cast data types, and prepare the data for business analysis.

Examples:

- `stg_customers`
- `stg_orders`
- `stg_items`
- `stg_products`
- `stg_stores`
- `stg_supplies`

### Marts Layer

The marts layer contains the final business models used for analysis.

Main marts models:

- `dim_customer_segments`
- `fct_segment_product_preferences`

---

## Model: `dim_customer_segments`

### Purpose

`dim_customer_segments` is a dimension model that creates one row per customer and classifies each customer into a segment based on:

1. Purchase frequency
2. Total product value

This model helps identify different types of customers based on how often they order and how much value they generate.

### Grain

One row per customer.

```text
customer_id
```

### Key Metrics

| Column | Description |
|---|---|
| `customer_id` | Unique customer identifier |
| `total_orders` | Total number of distinct orders placed by the customer |
| `total_products_purchased` | Total number of products purchased by the customer |
| `total_product_value` | Total value of products purchased by the customer |
| `avg_product_price` | Average price of products purchased by the customer |
| `customer_segment` | Customer segment classification |

### Customer Segments

| Segment | Meaning |
|---|---|
| `High-value frequent customer` | Customers who order often and generate high total product value |
| `High-value occasional customer` | Customers who generate high value but order less frequently |
| `Low-value frequent customer` | Customers who order often but generate lower total product value |
| `Medium-value regular customer` | Customers with medium value and regular purchase behavior |
| `Low-value occasional customer` | Customers who order less frequently and generate lower total product value |

### Segmentation Method

The model uses `ntile(3)` to divide customers into low, medium, and high groups based on actual data distribution.

```sql
ntile(3) over (
    order by total_product_value
) as value_group
```

```sql
ntile(3) over (
    order by total_orders
) as frequency_group
```

This method is useful because it avoids manually choosing fixed thresholds. Since product prices and customer spending levels can vary, percentile-based grouping creates more meaningful segments.

### Example Logic

```sql
case
    when value_group = 3 and frequency_group = 3
        then 'High-value frequent customer'

    when value_group = 3 and frequency_group < 3
        then 'High-value occasional customer'

    when value_group < 3 and frequency_group = 3
        then 'Low-value frequent customer'

    when value_group = 2 and frequency_group = 2
        then 'Medium-value regular customer'

    else 'Low-value occasional customer'
end as customer_segment
```

---

## Model: `fct_segment_product_preferences`

### Purpose

`fct_segment_product_preferences` is a fact model that measures product preferences by customer segment.

It helps answer:

> **Which product types are most popular and most valuable for each customer segment?**

### Grain

One row per customer segment and product type.

```text
customer_segment + product_type
```

### Key Metrics

| Column | Description |
|---|---|
| `customer_segment` | Customer group from `dim_customer_segments` |
| `product_type` | Product category purchased by the segment |
| `number_of_customers` | Number of distinct customers in the segment who purchased the product type |
| `total_orders` | Total number of orders for the segment and product type |
| `total_products_purchased` | Total number of products purchased |
| `total_product_value` | Total product value generated |
| `avg_product_price` | Average price of products purchased |
| `avg_order_value` | Average product value per order |
| `avg_products_per_order` | Average number of products purchased per order |

---

## Key Business Insights

### 1. High-value frequent customers are the strongest retention group

High-value frequent customers order often and generate strong total product value. They are likely the most loyal and valuable customers.

For this group, beverages generated a large amount of product value, and jaffles also contributed meaningful value. This shows that high-value frequent customers are important across multiple product types.

**Business recommendation:**

The business should focus on retaining this group through:

- VIP loyalty rewards
- Exclusive offers
- Early access to new products
- Personalized product recommendations

---

### 2. High-value occasional customers have strong spending potential

High-value occasional customers do not order as frequently, but they generate high product value when they do purchase. This means they may buy expensive products or place larger orders occasionally.

In the product preference result, high-value occasional customers generated especially strong value from jaffles and beverages.

**Business recommendation:**

The business should encourage this group to purchase more often through:

- Re-engagement emails
- Limited-time promotions
- Personalized product reminders
- Free shipping or discount thresholds

---

### 3. Low-value frequent customers are good upsell targets

Low-value frequent customers order often but generate lower value compared with high-value customers. This means they are engaged, but they may be buying lower-priced products.

This segment is a strong opportunity for upselling because they already have repeat purchase behavior.

**Business recommendation:**

The business should increase basket size through:

- Bundle deals
- Add-on offers at checkout
- Cross-sell recommendations
- Premium product suggestions

---

### 4. Low-value occasional customers need activation strategies

Low-value occasional customers purchase less often and generate lower product value. They may be new customers, one-time buyers, or customers who are not strongly engaged yet.

**Business recommendation:**

The business should focus on basic activation strategies such as:

- Welcome-back coupons
- First-time repeat purchase discounts
- Simple product bundles
- Low-cost product recommendations

---

### 5. Product strategy should differ by segment

The product preference model shows that beverages are purchased across all customer segments, while jaffles generally have higher average product prices and higher average order values.

This suggests that beverages may be useful for driving repeat purchases, while jaffles may be useful for increasing order value.

**Business recommendation:**

- Use beverages to encourage repeat purchases.
- Use jaffles to increase average order value.
- Promote product bundles that combine beverages with higher-value products.

---

## Business Recommendations by Segment

| Customer Segment | Business Goal | Suggested Strategy |
|---|---|---|
| High-value frequent customer | Retain loyalty | VIP rewards, loyalty program, personalized offers |
| High-value occasional customer | Increase purchase frequency | Re-engagement campaigns, limited-time offers |
| Low-value frequent customer | Increase order value | Bundles, upselling, premium recommendations |
| Medium-value regular customer | Move to high-value | Cross-sell products, targeted promotions |
| Low-value occasional customer | Increase engagement | Discounts, beginner offers, awareness campaigns |

---

## Final Conclusion

This project shows that customer segmentation can help the business better understand customer behavior and product preferences. By combining purchase frequency and total product value, the business can identify high-value customers, occasional high spenders, frequent low-value customers, and low-engagement customers.

The fact model connects customer segments to product types, helping the business understand which products are most important to each customer group.

The main business takeaway is:

> The business should use different strategies for different customer segments. High-value frequent customers should be retained, high-value occasional customers should be encouraged to purchase more often, low-value frequent customers should be upsold, and low-value occasional customers should be activated through simple promotions.

---

## How to Run the Project

Run all models:

```bash
dbt run
```

Run the customer segmentation model:

```bash
dbt run --select +dim_customer_segments
```

Run the product preference fact model:

```bash
dbt run --select +fct_segment_product_preferences
```

Run all tests:

```bash
dbt test
```

Run only marts tests:

```bash
dbt test --select marts
```

---

## Project Readability Notes

This project is organized with clear naming conventions:

| Prefix | Meaning |
|---|---|
| `stg_` | Staging model that cleans raw data |
| `dim_` | Dimension model that describes a business entity |
| `fct_` | Fact model that measures business activity |

The final structure is easy to understand:

```text
staging models
  ↓
dim_customer_segments
  ↓
fct_segment_product_preferences
```

This structure improves readability because each model has a clear purpose:

- Staging models clean the raw data.
- The dimension model classifies customers.
- The fact model measures product preferences by customer segment.

---

## Future Improvements

This analysis can be extended by adding:

- Product profitability using supply costs
- Store-level customer segment analysis
- Monthly customer segment trends
- Customer retention analysis
- Average days between orders
- Product bundle recommendation analysis