import streamlit as st
import psycopg2
import pandas as pd

#https://www.datacamp.com/tutorial/tutorial-postgresql-python
#https://www.psycopg.org/docs/
#https://docs.streamlit.io/

if "is_loggedin" not in st.session_state:
    st.session_state["is_loggedin"] = False

conn = psycopg2.connect(database = "dmql", user = "postgres", host= 'localhost', password = "1234", port = 5432)
cur = conn.cursor()

st.markdown("<h1 style='text-align: center;'>Accounting Software</h1>", unsafe_allow_html=True)
if(not st.session_state["is_loggedin"]):
    st.markdown("<p1 style='text-align: center;'>Login below to access the software</p1>", unsafe_allow_html=True)
    user_id = st.text_input("username")
    user_password = st.text_input("password", type="password")
    if(st.button("Login")):
        cur.execute("SELECT * FROM users WHERE user_id = " + user_id + " and user_password = \'" + user_password + "\';")
        if(cur.fetchall()):
            st.session_state["is_loggedin"] = True
            st.success("Login Successful")
        else:
            st.error("Login Failed, incorrect username or password")
else:
    input = st.text_input("Enter table Name to view it or enter query in the below field")

    list = []
    column_names = []
    data = None
    def execute_table_details_from_name(name):
        if(name == 'users'):
            st.error("Error: Table name Does not exists")
            return
        global column_names, list, data
        cur.execute("SELECT * FROM " + name + ";")
        column_names = [desc[0] for desc in cur.description]
        list = cur.fetchall()
        data = [dict(zip(column_names, values)) for values in list]
        df = pd.DataFrame(data)
        if(df.empty == False):
            st.table(df)

    # with col1:
    st.sidebar.markdown("<h1 style='text-align: center;'>Tables</h1>", unsafe_allow_html=True)
    if(st.sidebar.button('General Ledger')): #1
        execute_table_details_from_name("general_ledger")

    if(st.sidebar.button('Invoices')): #2
        execute_table_details_from_name("invoices")

    if(st.sidebar.button('Bills')): #3
        execute_table_details_from_name("bills")

    if(st.sidebar.button('Invoice Items')): #4
        execute_table_details_from_name("invoice_items")

    if(st.sidebar.button('Bill Items')): #5
        execute_table_details_from_name("bill_items")

    if(st.sidebar.button('Expenses')): #6
        execute_table_details_from_name("expenses")

    if(st.sidebar.button('Expense Items')): #7
        execute_table_details_from_name("expense_items")

    if(st.sidebar.button('Payments')): #8
        execute_table_details_from_name("payments")

    if(st.sidebar.button('Customers')): #9
        execute_table_details_from_name("customers")

    if(st.sidebar.button('Vendors')): #10
        execute_table_details_from_name("vendors")

    if(st.sidebar.button('Items')): #11
        execute_table_details_from_name("items")



    col20, col21, co22 = st.columns(3)

    if(input != ""):
        if(len(input) > 7 and (input[0:6].upper() == "SELECT" or input[0:6].upper() == "DELETE")):
            cur.execute(input)
            column_names = [desc[0] for desc in cur.description]
            list = cur.fetchall()
            data = [dict(zip(column_names, values)) for values in list]
            df = pd.DataFrame(data)
            st.table(df)
        else:
            try:
                execute_table_details_from_name(input)
            except Exception as e:
                st.error(f"Error: Table name Does not exists")
