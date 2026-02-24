create database travel_agency;
use travel_agency;

set sql_safe_updates =0;
update  payments
set amountpaid= 2200;

update  payments
set amountpaid= 200
where bookingid = 17;

-- Q.1 Identify the top 5 counties with the most customers

select Country, COUNT(customerid) AS Customer_Count
from Customers
group by Country
order by Customer_Count desc
limit 5;


-- Q.2 Rank Agents by Average Revenue generated
    
select ta.agentid,name, avg(totalamount) as avg_revenue,
rank() over (order by avg(totalamount) desc) as agentrank
from bookings b join tours t on t.tourid = b.tourid
join travelagents ta on ta.agentid = t.agentid
group by ta.agentid,name
order by agentrank;


-- Q.3 Group customers into buckets:
-- Low spenders (< 3k)
-- Medium spenders (3k–10k)
-- High spenders (> 10k)


SELECT 
    c.customerid,
    c.name,
    SUM(b.totalamount) AS total_spent,
    CASE 
        WHEN SUM(b.totalamount) < 3000 THEN 'Low Spender'
        WHEN SUM(b.totalamount) BETWEEN 3000 AND 10000 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS segment
FROM customers c
JOIN bookings b ON c.customerid = b.customerid join payments p on p.bookingid= b.bookingid
WHERE p.paymentstatus = "paid"
GROUP BY c.customerid, c.name
order by total_spent desc;


 -- Q.4 List each customer with total bookings, total spent, and average rating of tours booked
    
    select c.customerid,name as customer_name, count(b.bookingid) as total_booking, sum(totalamount) as total_spent ,round(avg(rating),1) average_rating 
    from bookings b join reviews r on b.bookingid = r.bookingid
	join customers c on c.customerid = b.customerid
    join payments p on b.bookingid = p.bookingid
    group by c.customerid, customer_name
    order by total_spent desc; 
    
    
-- Q.5  Find the most popular destination based on bookings

select destination, count(bookingid) as total_bookings from bookings b
join tours t on
b.tourid = t.tourid
group by destination
order by total_bookings desc
limit 1;

 -- Q.6 Find tours that are highly rated but low in bookings (potential opportunity).
 
     select t.tourid, t.destination, avg(rating) as average_rating , count(b.bookingid) total_booking from bookings b
     join reviews r on b.bookingid = r.bookingid
     join tours t on t.tourid = b.tourid
     group by t.tourid,t.destination
     having average_rating >= 4.5 and total_booking < 3
     order by total_booking ; 
     
     
-- Q.7 find destination with highest revenue
 
select t.tourid, destination , sum(totalamount) total_revenue from bookings b
join tours t on b.tourid = t.tourid
group by t.tourid,destination
order by total_revenue desc
limit 1;


-- Q.8 Find Customers who booked more than two tours and give them 20% concession

select  c.customerid,name,
sum(totalamount) as totalamount,
sum(totalamount)*0.8 as discounted_amount  
from bookings b join customers c on b.customerid = c.customerid
group by c.CustomerID,name
having count(bookingid) >= 2
order by discounted_amount desc;



-- Q.9 Which package type is booked the most

select t.packagetype, count(b.bookingid)  as booking_count
from bookings b
join tours t on b.tourid = t.tourid
group by t.packagetype
order by  booking_count desc
limit 1;

-- Q.10  Find the agent who has generated the highest revenue

select t.agentid,name, sum(b.totalamount) as total_revenue from bookings b
join tours t on 
b.tourid = b.tourid
join travelagents ta on
t.agentid = ta.agentid
group by t.agentid,name
order by total_revenue desc
limit 1;


-- Q.11  List all customers with pending paymentstatus and find out how much amount is pending

SELECT 
    c.CustomerID,Name,
    SUM(b.TotalAmount) AS Total_amount,
   SUM(p.Amountpaid) AS Total_Paid,
    (SUM(b.TotalAmount) - sum( p.Amountpaid)) AS Pending_Amount
FROM Customers c
JOIN Bookings b ON c.CustomerID = b.CustomerID
JOIN Payments p ON b.BookingID = p.BookingID
where paymentstatus ="pending"
GROUP BY c.CustomerID, Name;
      
    
    -- Q.12 Find the agent who generated the highest revenue in High season
    
     select ta.agentid,ta.name as agent_name, sum(totalamount) highest_revenue from bookings b 
     join tours t on b.tourid = t. tourid
     join travelagents ta on ta.agentid = t.agentid
     where season="high"
     group by ta.agentid,agent_name
     order by highest_revenue desc
     limit 1;
     
     -- Q.13 Identify customers who booked tours in multiple seasons. 
     
     select c.customerid, name customer_name, count(distinct season) as multiple_season from bookings b
     join customers c on b.customerid = c.customerid
     join tours t on b.tourid= t.tourid
     group by  c.customerid,customer_name
	having multiple_season > 1;
    
    
  -- Q.14 Calculate the revenue lost due to cancellations in each quarter of the last 2 years.

select year(bookingdate) as year,
    quarter(bookingdate) as quarter,
    sum(totalamount) as lost_revenue
from bookings b join payments p on b.bookingid = p.bookingid
where paymentstatus = 'cancelled'
	and bookingdate >= DATE_SUB(CURDATE(), INTERVAL 2 YEAR)
group by year(bookingdate), quarter (bookingdate)
order by year(bookingdate);

-- Q.15 Find customers with more than 3 pending payments in the last 12 months and calculate their total pending amount.

SELECT 
    c.customerid,
    c.name,
    COUNT(p.paymentid) AS pending_payments,
    SUM(b.totalamount) AS total_pending_amount
FROM customers c
JOIN bookings b ON c.customerid = b.customerid
LEFT JOIN payments p ON b.bookingid = p.bookingid
WHERE p.paymentstatus = 'Pending'
  AND p.paymentdate >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY c.customerid, c.name
HAVING COUNT(p.paymentid) > 1
ORDER BY total_pending_amount DESC;


-- Q.16  Compare average spending of loyalty members vs non-members, and check if loyalty members actually spend more.

SELECT 
    c.loyaltymember,
    AVG(b.totalamount) AS avg_spending
FROM customers c
JOIN bookings b ON c.customerid = b.customerid 
join payments p on b.bookingid = p.bookingid 
WHERE p.paymentstatus = "paid"
GROUP BY c.loyaltymember;



 
 
 
 
 
 
 