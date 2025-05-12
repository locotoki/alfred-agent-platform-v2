import streamlit as st

st.title("Alfred Chat Interface")

st.write("Welcome to the Alfred Agent Platform")

message = st.text_input("Enter your message:")
if st.button("Send"):
    st.write(f"You sent: {message}")
    st.write("Response: I'm a placeholder response")
