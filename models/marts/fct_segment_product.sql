with customer_segments as (

    select *
    from {{ ref('dim_customer_segments') }}

),

segment_product_preferences as (

    select
        customer_segments.customer_segment,
        products.product_type,

        count(distinct orders.customer_id) as number_of_customers,
        count(distinct orders.order_id) as total_orders,
        count(items.item_id) as total_products_purchased,

        sum(products.product_price) as total_product_value,
        avg(products.product_price) as avg_product_price,

        safe_divide(
            sum(products.product_price),
            count(distinct orders.order_id)
        ) as avg_order_value,

        safe_divide(
            count(items.item_id),
            count(distinct orders.order_id)
        ) as avg_products_per_order

    from customer_segments

    left join {{ ref('stg_orders') }} as orders
        on customer_segments.customer_id = orders.customer_id

    left join {{ ref('stg_items') }} as items
        on orders.order_id = items.order_id

    left join {{ ref('stg_products') }} as products
        on items.sku = products.sku

    group by
        customer_segments.customer_segment,
        products.product_type

)

select *
from segment_product_preferences
order by
    customer_segment,
    total_product_value desc