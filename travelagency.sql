create database travel_agency2;
use travel_agency2;

-- Q.1  Find the top 3 agent who has generated the highest revenue and calculate what % of the total revenue this top agents contributes

select t.agent_id,agent_name,sum(total_amount) as total_revenue, 
concat(round(sum(total_amount)/( select sum(total_amount) from bookings)*100,1)," " ,"%")as revenue_percentage from travelagents t join 
bookings b on t.agent_id= b.agent_id
group by t.agent_id,agent_name
order by total_revenue desc
limit 3;


-- Q.2  Find the most popular destination based on bookings

select destination, count(booking_id) as total_bookings from bookings b
join tours t on
b.tour_id = t.tour_id
group by destination
order by total_bookings desc
limit 1;


-- Q.3 Identify the top 5 counties with the most customers

select Country, COUNT(customer_id) AS Customer_Count
from Customers
group by Country
order by Customer_Count desc
limit 5;


 -- Q.4 List each customer with total bookings, total spent, and average rating of tours booked
    
    select c.customer_id,first_name,last_name, count(b.booking_id) as total_booking, sum(total_amount) as total_spent ,round(avg(rating),1) average_rating 
    from bookings b join customers c on c.customer_id = b.customer_id
	join reviews r on b.booking_id = r.booking_id
    group by c.customer_id,first_name,last_name
    order by total_spent desc; 

-- Q.5 find destinations with highest revenue and how much % do they contribute to total_revenue
 
 select destination, sum(total_amount) as total_revenue, round((sum(total_amount)/(select sum(total_amount) from bookings))*100,1) as per_contri from tours t 
 join bookings b on t.tour_id = b.tour_id
 group by destination 
 order by total_revenue desc;

-- Q.6 Rank Agents by Average Revenue generated
    
select ta.agent_id,agent_name, avg(total_amount) as avg_revenue,
rank() over (order by avg(total_amount) desc) as agentrank
from bookings b join travelagents ta on ta.agent_id = b.agent_id
group by ta.agent_id,agent_name
order by agentrank;

-- Q.7 find customers who have not made a bookings in last  1 year

select c.customer_id,first_name,last_name
from customers c where not exists (select customer_id from bookings b  where c.customer_id = b.customer_id
and b.booking_date >= date_sub(curdate(), interval 1 year));


-- Q.8 Group customers into buckets:
-- Low spenders (< 50k)
-- Medium spenders (50k–1 lac)
-- High spenders (> 1 lac) and give high spending customers 10% discount

SELECT 
    c.customer_id, c.first_name, c.last_name,
    SUM(total_amount) AS total_spent,
    CASE 
        WHEN SUM(total_amount) < 50000 THEN 'Low Spender'
        WHEN SUM(total_amount) BETWEEN 50000 AND 100000 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS segment,
    CASE 
        WHEN SUM(total_amount) > 100000 THEN SUM(total_amount) * 0.10
        ELSE 0
    END AS discount_amount,
     SUM(total_amount) -
        CASE 
            WHEN SUM(total_amount) > 100000 THEN SUM(total_amount) * 0.1
		ELSE 0
        END AS amount_after_discount
FROM customers c
JOIN bookings b ON c.customer_id = b.customer_id
JOIN payments p ON p.booking_id = b.booking_id
WHERE p.status = 'paid'
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC;



-- Q.9 Identify customers who booked tours in multiple seasons with season names

  select distinct c.customer_id, first_name, last_name,t.season
from customers c join bookings b on c.customer_id = b.customer_id
join tours t on b.tour_id = t.tour_id
where c.customer_id in (
    select customer_id
    from bookings b2
    join tours t2 on b2.tour_id = t2.tour_id
    group by b2.customer_id,first_name, last_name
    having count(distinct t2.season) > 1)
order by c.customer_id, t.season;
     
    
 -- Q.10 Find tours that are highly rated but low in bookings (potential opportunity).
 
     select t.tour_id, t.destination, avg(rating) as average_rating , count(b.booking_id) total_booking from bookings b
     join reviews r on b.booking_id = r.booking_id
     join tours t on t.tour_id = b.tour_id
     group by t.tour_id,t.destination
     having average_rating >= 4.5 and total_booking < 3
     order by total_booking; 
     
     
-- Q.11 Find Customers who booked more than two tours and give them 20% concession

select c.customer_id,first_name,last_name,count(booking_id) as total_bookings,sum(total_amount) as total_amount,
(sum(total_amount)*0.2) discount,(sum(total_amount)-(sum(total_amount)*0.2))as amount_after_discount from customers c
join bookings b on c.customer_id = b.customer_id
group by c.customer_id, first_name,last_name
having total_bookings >=2;


-- Q.12  List all customers with pending payment status and find out how much amount is pending


select c.customer_id,first_name,last_name,p.status,sum(total_amount) as total_amount,sum(paid_amount) as paid_amount,
(sum(total_amount)- sum(paid_amount)) as remaining_amount from bookings b
left join customers c on b.customer_id = c.customer_id 
left join payments p on p.booking_id = b.booking_id 
where p.status="pending"
group by c.customer_id,first_name,last_name;
 
    
-- Q.13 Find the agents who generated the highest revenue season wise and find agents with their top season

select ta.agent_id, ta.agent_name, t.season,
sum(b.total_amount) as season_revenue,
case when sum(b.total_amount) = max(sum(b.total_amount)) over (partition by ta.agent_id)
then 'Top Season'
else ''
end as season_rank
from travelagents ta join bookings b on b.agent_id = ta.agent_id
join tours t on t.tour_id = b.tour_id
group by ta.agent_id, ta.agent_name, t.season
order by ta.agent_id, season_revenue desc;
     

  -- Q.14 Calculate the revenue lost due to cancellations in each quarter of the last 2 years.

select year(booking_date) as year,
    quarter(booking_date) as quarter,
    sum(total_amount) as lost_revenue
from bookings b join payments p on b.booking_id = p.booking_id
where b.status = 'cancelled'
	and booking_date >= DATE_SUB(CURDATE(), interval 2 year)
group by year(booking_date), quarter (booking_date)
order by year(booking_date);

-- Q.15 Find customers with more than 1 pending payments in the last 2 years and calculate their total pending amount.

SELECT 
    c.customer_id,
   first_name,last_name,
    COUNT(p.payment_id) AS pending_payments,
	SUM(b.total_amount)-sum(paid_amount) as total_pending_amount
FROM customers c
JOIN bookings b ON c.customer_id = b.customer_id
JOIN payments p ON b.booking_id = p.booking_id
WHERE p.status = 'Pending'
  AND p.paid_date >= DATE_SUB(CURDATE(), INTERVAL 2 year)
GROUP BY c.customer_id, first_name,last_name
HAVING COUNT(p.payment_id) > 1
ORDER BY total_pending_amount DESC;


-- Q.16  Compare average spending of loyalty members vs non-members, and check if loyalty members actually spend more.

SELECT 
    loyalty_member,
    AVG(total_amount) AS avg_spending
FROM customers c
JOIN bookings b ON c.customer_id = b.customer_id 
join payments p on b.booking_id = p.booking_id 
WHERE p.status = "paid"
GROUP BY loyalty_member;



 
 
 
 