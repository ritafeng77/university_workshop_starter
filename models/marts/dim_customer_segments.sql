with customer_product_metrics as (

    select
        orders.customer_id,

        count(distinct orders.order_id) as total_orders,
        count(items.item_id) as total_products_purchased,
        sum(products.product_price) as total_product_value,
        avg(products.product_price) as avg_product_price

    from {{ ref('stg_orders') }} as orders

    left join {{ ref('stg_items') }} as items
        on orders.order_id = items.order_id

    left join {{ ref('stg_products') }} as products
        on items.sku = products.sku

    group by orders.customer_id

),

customer_rankings as (

    select
        customer_id,
        total_orders,
        total_products_purchased,
        total_product_value,
        avg_product_price,

        ntile(3) over (
            order by total_product_value
        ) as value_group,

        ntile(3) over (
            order by total_orders
        ) as frequency_group

    from customer_product_metrics

),

customer_segments as (

    select
        customer_id,
        total_orders,
        total_products_purchased,
        total_product_value,
        avg_product_price,

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

    from customer_rankings

)

select *
from customer_segments