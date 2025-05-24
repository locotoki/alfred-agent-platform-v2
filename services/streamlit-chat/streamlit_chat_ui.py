import streamlit as stLFLFst.title("Alfred Chat UI")LFst.header("Welcome to Alfred Chat")
st.write("Status: Connected")

with st.sidebar:
    st.header("Settings")
    st.checkbox("Use direct model inference", value=True)

st.text_input("Your message", placeholder="Type your message here...")
st.button("Send")
