# import modules
import pandas as pd
import psycopg2
import psycopg2.extras as extras

# define insert data function
def execute_values(conn, df, table):
    tuples = [tuple(x) for x in df.to_numpy()]
    cols = ",".join(list(df.columns))
    # SQL query to execute
    query = "INSERT INTO %s(%s) VALUES %%s" % (table, cols)
    cursor = conn.cursor()
    try:
        extras.execute_values(cursor, query, tuples)
        conn.commit()
    except (Exception, psycopg2.DatabaseError) as error:
        print("Error: %s" % error)
        conn.rollback()
        cursor.close()
    print("the dataframe is inserted")
    cursor.close()
    
# create connection
conn = psycopg2.connect(database="amazon", user="postgres", password="dhq")

# load csv files
df1 = pd.read_csv("credits.csv", delimiter=",")
df2 = pd.read_csv("titles.csv", delimiter=",").drop("description",axis=1)
execute_values(conn, df1, "credits")
execute_values(conn, df2, "titles")
