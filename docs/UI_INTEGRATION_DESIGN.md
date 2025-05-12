# UI Integration Design for LLM Selection

## Overview

This document outlines the design for integrating LLM model selection capabilities into the Alfred UI components, specifically the Streamlit chat interface and admin dashboard.

## Components

### 1. Streamlit Chat UI Enhancements

The Streamlit Chat UI will be enhanced to allow model selection and display model-specific information.

#### Model Selection Dropdown

```python
def sidebar_config():
    """Setup and handle sidebar configuration."""
    st.sidebar.title("Configuration")
    
    # API URL configuration
    api_url = st.sidebar.text_input(
        "Alfred API URL", 
        value=st.session_state.api_url
    )
    if api_url != st.session_state.api_url:
        st.session_state.api_url = api_url
    
    # Model selection
    if "available_models" not in st.session_state:
        st.session_state.available_models = fetch_available_models()
        
    models = st.session_state.available_models
    model_options = [m["name"] for m in models]
    
    selected_model = st.sidebar.selectbox(
        "AI Model",
        options=model_options,
        index=model_options.index(st.session_state.get("selected_model", model_options[0]))
    )
    
    if selected_model != st.session_state.get("selected_model"):
        st.session_state.selected_model = selected_model
        
    # Show model information
    show_model_info = st.sidebar.checkbox("Show Model Info", value=False)
    if show_model_info:
        model_info = next((m for m in models if m["name"] == selected_model), None)
        if model_info:
            st.sidebar.write("**Model Details:**")
            st.sidebar.write(f"Provider: {model_info['provider']}")
            st.sidebar.write(f"Type: {model_info['model_type']}")
            st.sidebar.write(f"Description: {model_info['description']}")
    
    # Advanced parameters
    show_advanced = st.sidebar.checkbox("Advanced Parameters", value=False)
    if show_advanced:
        temperature = st.sidebar.slider(
            "Temperature", 
            min_value=0.0, 
            max_value=1.0, 
            value=st.session_state.get("temperature", 0.7),
            step=0.05
        )
        st.session_state.temperature = temperature
        
        top_p = st.sidebar.slider(
            "Top P", 
            min_value=0.0, 
            max_value=1.0, 
            value=st.session_state.get("top_p", 0.95),
            step=0.05
        )
        st.session_state.top_p = top_p
    
    # Clear chat button
    if st.sidebar.button("Clear Chat History"):
        st.session_state.messages = []
        st.rerun()

def fetch_available_models():
    """Fetch available models from the Model Registry."""
    try:
        response = requests.get(
            f"{st.session_state.api_url}/api/v1/model/available",
            headers={"Authorization": f"Bearer {st.session_state.get('token', '')}"}
        )
        if response.status_code == 200:
            return response.json()
        else:
            st.sidebar.error(f"Failed to load models: {response.status_code}")
            return [{"name": "default", "provider": "unknown", "model_type": "text", "description": "Default model"}]
    except Exception as e:
        st.sidebar.error(f"Error loading models: {str(e)}")
        return [{"name": "default", "provider": "unknown", "model_type": "text", "description": "Default model"}]
```

#### API Integration Updates

```python
def send_message(message: str) -> str:
    """Send a message to the Alfred Bot API and get the response."""
    try:
        # Call the Alfred API endpoint
        url = f"{st.session_state.api_url}/api/chat"
        
        # Include selected model and parameters if set
        payload = {
            "message": message,
            "user_id": SESSION_USER_ID,
            "channel_id": SESSION_CHANNEL_ID
        }
        
        # Add model selection if specified
        if "selected_model" in st.session_state:
            payload["model"] = st.session_state.selected_model
            
        # Add advanced parameters if specified
        if "temperature" in st.session_state:
            if "parameters" not in payload:
                payload["parameters"] = {}
            payload["parameters"]["temperature"] = st.session_state.temperature
            
        if "top_p" in st.session_state:
            if "parameters" not in payload:
                payload["parameters"] = {}
            payload["parameters"]["top_p"] = st.session_state.top_p
        
        if st.session_state.debug_mode:
            st.sidebar.write("Request:", payload)
            
        response = requests.post(
            url,
            json=payload,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            data = response.json()
            if st.session_state.debug_mode:
                st.sidebar.write("Response:", data)
            return data.get("response", "No response received")
        else:
            error_msg = f"Error: {response.status_code} - {response.text}"
            if st.session_state.debug_mode:
                st.sidebar.write("Error:", error_msg)
            return error_msg
    except Exception as e:
        error_msg = f"Error communicating with Alfred: {str(e)}"
        logger.error("api_communication_failed", error=str(e))
        if st.session_state.debug_mode:
            st.sidebar.write("Exception:", error_msg)
        return error_msg
```

#### Response Information Display

```python
def display_response(response_data):
    """Display response with model information."""
    # Display the actual response content
    st.markdown(response_data.get("content", "No response content"))
    
    # Show model info if present and debug mode is enabled
    if st.session_state.debug_mode and "model_info" in response_data:
        with st.expander("Response Information"):
            st.write(f"**Model:** {response_data['model_info'].get('name', 'Unknown')}")
            st.write(f"**Tokens:** {response_data['model_info'].get('tokens', 'Unknown')}")
            st.write(f"**Time:** {response_data['model_info'].get('time_ms', 'Unknown')} ms")
```

### 2. Admin Dashboard Integration

The Admin Dashboard will include a new "Models" section for managing model configuration.

#### Models Management Page

```javascript
import React, { useState, useEffect } from 'react';
import { Table, Button, Modal, Form, Input, Select, Slider, Tag, message } from 'antd';
import axios from 'axios';

const ModelsPage = () => {
  const [models, setModels] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modalVisible, setModalVisible] = useState(false);
  const [editingModel, setEditingModel] = useState(null);
  const [form] = Form.useForm();
  
  useEffect(() => {
    fetchModels();
  }, []);
  
  const fetchModels = async () => {
    setLoading(true);
    try {
      const response = await axios.get('/api/v1/model/available');
      setModels(response.data);
    } catch (error) {
      message.error('Failed to load models');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };
  
  const handleEdit = (model) => {
    setEditingModel(model);
    form.setFieldsValue({
      name: model.name,
      provider: model.provider,
      model_type: model.model_type,
      description: model.description,
      // Set other fields
    });
    setModalVisible(true);
  };
  
  const handleSave = async () => {
    try {
      const values = await form.validateFields();
      
      if (editingModel) {
        // Update existing model
        await axios.put(`/api/v1/model/${editingModel.id}`, values);
        message.success('Model updated successfully');
      } else {
        // Create new model
        await axios.post('/api/v1/model', values);
        message.success('Model created successfully');
      }
      
      setModalVisible(false);
      setEditingModel(null);
      form.resetFields();
      fetchModels();
    } catch (error) {
      message.error('Error saving model');
      console.error(error);
    }
  };
  
  const columns = [
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
    },
    {
      title: 'Provider',
      dataIndex: 'provider',
      key: 'provider',
      render: (provider) => {
        let color;
        switch (provider) {
          case 'openai': color = 'green'; break;
          case 'anthropic': color = 'blue'; break;
          case 'ollama': color = 'orange'; break;
          default: color = 'default';
        }
        return <Tag color={color}>{provider}</Tag>;
      }
    },
    {
      title: 'Type',
      dataIndex: 'model_type',
      key: 'model_type',
    },
    {
      title: 'Capabilities',
      dataIndex: 'capabilities',
      key: 'capabilities',
      render: (capabilities) => (
        <>
          {capabilities && capabilities.map(cap => (
            <Tag key={cap.capability}>{cap.capability}</Tag>
          ))}
        </>
      )
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (_, record) => (
        <Button type="link" onClick={() => handleEdit(record)}>
          Edit
        </Button>
      )
    }
  ];
  
  return (
    <div>
      <h1>Models Management</h1>
      <Button 
        type="primary" 
        style={{ marginBottom: 16 }}
        onClick={() => {
          setEditingModel(null);
          form.resetFields();
          setModalVisible(true);
        }}
      >
        Add Model
      </Button>
      
      <Table 
        columns={columns} 
        dataSource={models} 
        loading={loading}
        rowKey="id"
      />
      
      <Modal
        title={editingModel ? "Edit Model" : "Add Model"}
        visible={modalVisible}
        onOk={handleSave}
        onCancel={() => {
          setModalVisible(false);
          setEditingModel(null);
        }}
        width={800}
      >
        <Form form={form} layout="vertical">
          <Form.Item
            name="name"
            label="Model Name"
            rules={[{ required: true, message: 'Please enter model name' }]}
          >
            <Input />
          </Form.Item>
          
          <Form.Item
            name="provider"
            label="Provider"
            rules={[{ required: true, message: 'Please select provider' }]}
          >
            <Select>
              <Select.Option value="openai">OpenAI</Select.Option>
              <Select.Option value="anthropic">Anthropic</Select.Option>
              <Select.Option value="ollama">Ollama</Select.Option>
              <Select.Option value="custom">Custom</Select.Option>
            </Select>
          </Form.Item>
          
          <Form.Item
            name="model_type"
            label="Model Type"
            rules={[{ required: true, message: 'Please select model type' }]}
          >
            <Select>
              <Select.Option value="chat">Chat</Select.Option>
              <Select.Option value="completion">Completion</Select.Option>
              <Select.Option value="embedding">Embedding</Select.Option>
              <Select.Option value="vision">Vision</Select.Option>
            </Select>
          </Form.Item>
          
          <Form.Item
            name="description"
            label="Description"
          >
            <Input.TextArea rows={3} />
          </Form.Item>
          
          {/* More form fields can be added here */}
        </Form>
      </Modal>
    </div>
  );
};

export default ModelsPage;
```

#### Model Usage Dashboard

```javascript
import React, { useState, useEffect } from 'react';
import { Card, Row, Col, Statistic, Select, DatePicker, Table, Spin } from 'antd';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import axios from 'axios';
import moment from 'moment';

const { RangePicker } = DatePicker;

const ModelUsageDashboard = () => {
  const [selectedModel, setSelectedModel] = useState('all');
  const [dateRange, setDateRange] = useState([moment().subtract(7, 'days'), moment()]);
  const [usageData, setUsageData] = useState([]);
  const [statsData, setStatsData] = useState({});
  const [modelOptions, setModelOptions] = useState([]);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    fetchModels();
  }, []);
  
  useEffect(() => {
    if (selectedModel && dateRange) {
      fetchUsageData();
      fetchStats();
    }
  }, [selectedModel, dateRange]);
  
  const fetchModels = async () => {
    try {
      const response = await axios.get('/api/v1/model/available');
      const models = response.data;
      setModelOptions([
        { label: 'All Models', value: 'all' },
        ...models.map(model => ({ label: model.name, value: model.id }))
      ]);
    } catch (error) {
      console.error('Failed to load models', error);
    }
  };
  
  const fetchUsageData = async () => {
    setLoading(true);
    try {
      const startDate = dateRange[0].format('YYYY-MM-DD');
      const endDate = dateRange[1].format('YYYY-MM-DD');
      
      const response = await axios.get('/api/v1/model/statistics', {
        params: {
          model_id: selectedModel !== 'all' ? selectedModel : undefined,
          start_date: startDate,
          end_date: endDate
        }
      });
      
      setUsageData(response.data.usage_over_time);
    } catch (error) {
      console.error('Failed to load usage data', error);
    } finally {
      setLoading(false);
    }
  };
  
  const fetchStats = async () => {
    try {
      const startDate = dateRange[0].format('YYYY-MM-DD');
      const endDate = dateRange[1].format('YYYY-MM-DD');
      
      const response = await axios.get('/api/v1/model/statistics/summary', {
        params: {
          model_id: selectedModel !== 'all' ? selectedModel : undefined,
          start_date: startDate,
          end_date: endDate
        }
      });
      
      setStatsData(response.data);
    } catch (error) {
      console.error('Failed to load statistics', error);
    }
  };
  
  return (
    <div className="model-usage-dashboard">
      <h1>Model Usage Dashboard</h1>
      
      <div className="dashboard-controls" style={{ marginBottom: 20 }}>
        <Row gutter={16}>
          <Col span={8}>
            <Select
              style={{ width: '100%' }}
              value={selectedModel}
              onChange={setSelectedModel}
              options={modelOptions}
              placeholder="Select Model"
            />
          </Col>
          <Col span={12}>
            <RangePicker
              value={dateRange}
              onChange={setDateRange}
              style={{ width: '100%' }}
            />
          </Col>
        </Row>
      </div>
      
      <Spin spinning={loading}>
        <div className="dashboard-stats">
          <Row gutter={16}>
            <Col span={6}>
              <Card>
                <Statistic
                  title="Total Requests"
                  value={statsData.total_requests || 0}
                />
              </Card>
            </Col>
            <Col span={6}>
              <Card>
                <Statistic
                  title="Total Tokens"
                  value={statsData.total_tokens || 0}
                />
              </Card>
            </Col>
            <Col span={6}>
              <Card>
                <Statistic
                  title="Avg Response Time"
                  value={statsData.avg_response_time || 0}
                  suffix="ms"
                  precision={0}
                />
              </Card>
            </Col>
            <Col span={6}>
              <Card>
                <Statistic
                  title="Error Rate"
                  value={statsData.error_rate || 0}
                  suffix="%"
                  precision={2}
                />
              </Card>
            </Col>
          </Row>
        </div>
        
        <div className="usage-chart" style={{ marginTop: 20, height: 400 }}>
          <ResponsiveContainer width="100%" height="100%">
            <LineChart
              data={usageData}
              margin={{ top: 5, right: 30, left: 20, bottom: 5 }}
            >
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Line type="monotone" dataKey="requests" stroke="#8884d8" name="Requests" />
              <Line type="monotone" dataKey="tokens" stroke="#82ca9d" name="Tokens" />
            </LineChart>
          </ResponsiveContainer>
        </div>
        
        {/* Additional tables and charts can be added here */}
        
      </Spin>
    </div>
  );
};

export default ModelUsageDashboard;
```

### 3. API Endpoint Updates

The API endpoints in agent-core will need updates to support model selection:

```python
@router.post("/api/chat")
async def chat_endpoint(request: ChatRequest):
    """Enhanced chat endpoint with model selection."""
    # Extract model selection if present
    model_id = request.model if hasattr(request, 'model') else None
    parameters = request.parameters if hasattr(request, 'parameters') else {}
    
    # Call model router if available
    if model_id or settings.ENABLE_MODEL_ROUTING:
        try:
            # Prepare payload for model router
            router_payload = {
                "content": request.message,
                "content_type": "text",
                "parameters": parameters
            }
            
            # Add model_id if specified
            if model_id:
                router_payload["model_id"] = model_id
                
            # Call model router
            router_response = await model_router_client.generate(router_payload)
            
            # Format response with model info
            response = {
                "response": router_response["content"],
                "model_info": {
                    "name": router_response["model"],
                    "tokens": router_response["usage"]["total_tokens"],
                    "time_ms": router_response["time_ms"]
                }
            }
            
            return response
        except Exception as e:
            # Fall back to legacy path on error
            logger.error(f"Model router error: {str(e)}")
            response = {"response": f"Error: {str(e)}"}
            return response
    
    # Legacy path - direct model call
    # (Existing implementation)
```

## UI Customization Flow

1. **Model Selection**:
   - User selects model from dropdown in Streamlit UI
   - Selection is stored in session state
   - Selected model is sent with each request

2. **Parameter Adjustment**:
   - Advanced users can adjust temperature, top_p, etc.
   - Parameters are stored in session state
   - Parameters are sent with requests

3. **Response Display**:
   - Responses include model information
   - Debug mode shows detailed stats
   - Chat history tracks model used for each message

## Admin Capabilities

1. **Model Management**:
   - View all available models
   - Add new models to the registry
   - Edit model configurations
   - View model capabilities

2. **Usage Monitoring**:
   - Track usage across models
   - View performance metrics
   - Analyze token consumption
   - Monitor error rates

3. **Rule Configuration**:
   - Set up model selection rules
   - Configure default parameters
   - Define fallback behavior
   - Set cost thresholds

## Implementation Plan

### 1. Streamlit UI Updates

1. Update `streamlit_chat_ui.py`:
   - Add model selection dropdown
   - Implement parameter controls
   - Enhance message display
   - Update API request format

2. Create model info helper:
   - Add functions to fetch available models
   - Format model information display
   - Cache model listings

### 2. Admin Dashboard Updates

1. Create new React components:
   - ModelsPage component
   - ModelUsageDashboard component
   - ModelConfigEditor component

2. Update routing:
   - Add routes for new components
   - Update navigation menu

3. Implement API clients:
   - Create model registry client
   - Implement usage statistics client

### 3. API Updates

1. Enhance agent-core endpoints:
   - Update chat endpoint to support model selection
   - Add model information to responses
   - Implement proper error handling

2. Add model router API client:
   - Create client for model router
   - Implement request formatting
   - Handle response parsing