# type: ignore
import streamlit as st

st.title("Alfred Chat UI")
st.header("Welcome to Alfred Chat")
st.write("Status: Connected")

with st.sidebar:
    st.header("Settings")
    st.checkbox("Use direct model inference", value=True)

st.text_input("Your message", placeholder="Type your message here...")
st.button("Send")
