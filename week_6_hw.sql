1. Show all customers whose last names start with T. Order them by first name from A-Z.
SELECT CONCAT(first_name, ' ', last_name) AS customer --Not strictly necessary, but more elegant.
FROM customer 
WHERE last_name LIKE 'T%' 
/*WHERE creates a conditional parameter, modified by LIKE, which takes a 
wild card character, %, to search for data that matches the string before the wild card.*/
ORDER BY first_name;
--This is how I sort the output. Default is alphabetically, so there is no need to add an extra parameter to do so.

2. Show all rentals returned from 5/28/2005 to 6/1/2005
SELECT * --asterisk selects all 
FROM rental --choosing desired data table
WHERE return_date BETWEEN '2005-05-28' AND '2005-06-01';
/*Using the WHERE conditional and modifying with BETWEEN, AND to pass inclusive dates, 
as strings and in ISO format, to get a date range.*/

3. How would you determine which movies are rented the most?
/*I will need to join data from three tables: rental table to get the inventory ids 
with the most rentals, inventory table to cross-reference the inventory id with the film id,
and film table to translate the film id to the film title. As follows:*/
SELECT film.title, COUNT(rental.inventory_id) AS times_rented
FROM rental
INNER JOIN inventory 
	    ON inventory.inventory_id= rental.inventory_id
INNER JOIN film 
	    ON film.film_id= inventory.film_id
GROUP BY film.title
ORDER BY times_rented DESC

4. Show how much each customer spent on movies (for all time) . Order them from least to most.
/*I will need to sum the amount each unique customer id paid, ASC is default so unecessary to add.*/
SELECT customer_id, SUM(amount) AS expenditure  
FROM payment
GROUP BY customer_id
ORDER BY expenditure

5. Which actor was in the most movies in 2006 (based on this dataset)? Be sure to alias the actor name and count as a more descriptive name. 
Order the results from most to least.

Gina Degeneres was in the most movies in 2006 at a whopping 42 movies. I came to this answer with the following query:

SELECT CONCAT(first_name,' ',last_name) AS actor, --organizing data by creating one element from two
	   COUNT(film_actor.actor_id) AS number_of_roles -- key element that will give my my count value  
FROM actor
INNER JOIN film_actor
	ON actor.actor_id = film_actor.actor_id
INNER JOIN film
	ON film.film_id = film_actor.film_id
WHERE release_year = 2006
GROUP BY actor, actor.actor_id
ORDER BY number_of_roles DESC;
/*  With this query, I had to leap-frog some data tables to get from release year -> film -> film id ->
actor id -> actor. So, I used JOIN to join the film, film_actor, and actor tables to get the desired result. */

6. Write an explaination for 4 and 5. Show the queries and explain what is happening in each one. Use the following link to understand how this works:
http://postgresguide.com/performance/explain.html 

/* Query for explanation of #4: */
EXPLAIN ANALYZE SELECT customer_id, SUM(amount) AS expenditure  
FROM payment
GROUP BY customer_id
ORDER BY expenditure

/* There are several sorts with this query, but only two small sequential scans. The Seq scans 
are accomplished in actual time well below their max time. 

Query for explanation of #5: */
EXPLAIN ANALYZE SELECT CONCAT(first_name,' ',last_name) AS actor, COUNT(film_actor.actor_id) AS number_of_roles  
FROM actor
INNER JOIN film_actor
	ON actor.actor_id = film_actor.actor_id
INNER JOIN film
	ON film.film_id = film_actor.film_id
WHERE release_year = 2006
GROUP BY actor, actor.actor_id
ORDER BY number_of_roles DESC;
/*  The output was quite lengthy for this explanation. I got a lot of information about memory
usage per action, which I imagine is vital when programming/working with massive quantities of data.
This query was significantly more involved than the query for question #4 and included
one additional seq scan. These scans still performed in actual time well below their max time. */


7. What is the average rental rate per genre?
/*  Similar to #3, it was necessary to JOIN three tables to associate the data I wanted to analyze.
I used the same query structure, modifying column names with AS function to give my output clarity. */
SELECT category.name AS category, AVG(film.rental_rate) AS avg_rate
FROM category
INNER JOIN film_category
	    ON film_category.category_id = category.category_id
INNER JOIN film 
	    ON film.film_id = film_category.film_id
GROUP BY category.name

8. How many films were returned late? Early? On time?
/* The COUNT command works here like an if/elif/else statement in python. It is used to count
conditional elements. Also used here is the date_part command to extract the day from the 
rental timestamps so that rental duration could be meaningful. */
SELECT 
COUNT(CASE
WHEN rental_duration > date_part('day', return_date - rental_date) THEN 'Returned Early'
	END) AS returned_early,
COUNT(CASE
WHEN rental_duration < date_part('day', return_date - rental_date) THEN 'Returned Late'
	END) AS returned_late,
COUNT(CASE
WHEN rental_duration = date_part('day', return_date - rental_date) THEN 'Returned On Time'
	END) AS returned_on_time
FROM film
INNER JOIN inventory
	ON inventory.film_id = film.film_id
INNER JOIN rental
	ON rental.inventory_id = inventory.inventory_id


9. What categories are the most rented and what are their total sales?
/*  This question was intense to answer because it required careful organization of logic
in order to sucessfully navigate thru all the tables to link the desired data. However, despite
being different in terms of scale, the logic used was the same as question #3 or #5 */

SELECT category.name AS category, SUM(amount) AS total_sales  
FROM category
INNER JOIN film_category
		ON film_category.category_id = category.category_id
INNER JOIN inventory 
	    ON inventory.film_id = film_category.film_id
INNER JOIN rental 
	    ON rental.inventory_id = inventory.inventory_id
INNER JOIN payment
	    ON payment.rental_id = rental.rental_id
GROUP BY category
ORDER BY COUNT(rental.rental_id)

10. Create a view for 8 and a view for 9. Be sure to name them appropriately. 
-- View for #8
CREATE VIEW timeliness_of_returns AS
SELECT 
COUNT(CASE
WHEN rental_duration > date_part('day', return_date - rental_date) THEN 'Returned Early'
	END) AS returned_early,
COUNT(CASE
WHEN rental_duration < date_part('day', return_date - rental_date) THEN 'Returned Late'
	END) AS returned_late,
COUNT(CASE
WHEN rental_duration = date_part('day', return_date - rental_date) THEN 'Returned On Time'
	END) AS returned_on_time
FROM film
INNER JOIN inventory
	ON inventory.film_id = film.film_id
INNER JOIN rental
	ON rental.inventory_id = inventory.inventory_id

-- View for #9
CREATE VIEW most_rented_categories AS
SELECT category.name AS category, SUM(amount) AS total_sales  
FROM category
INNER JOIN film_category
		ON film_category.category_id = category.category_id
INNER JOIN inventory 
	    ON inventory.film_id = film_category.film_id
INNER JOIN rental 
	    ON rental.inventory_id = inventory.inventory_id
INNER JOIN payment
	    ON payment.rental_id = rental.rental_id
GROUP BY category
ORDER BY COUNT(rental.rental_id)

Bonus:
Write a query that shows how many films were rented each month. Group them by category and month. 
