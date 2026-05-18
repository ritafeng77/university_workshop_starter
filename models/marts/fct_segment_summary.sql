with customer_segments as (

    select *
    from {{ ref('dim_customer_segments') }}

),

segment_summary as (

    select
        customer_segment,

        count(distinct customer_id) as number_of_customers,

        sum(total_orders) as total_orders,
        sum(total_products_purchased) as total_products_purchased,
        sum(total_product_value) as total_product_value,

        avg(total_orders) as avg_orders_per_customer,
        avg(total_products_purchased) as avg_products_per_customer,
        avg(total_product_value) as avg_value_per_customer,
        avg(avg_product_price) as avg_product_price

    from customer_segments

    group by customer_segment

)

select *
from segment_summary
order by total_product_value desc