require('dotenv').config();
const axios = require('axios');
const jwt = require('jsonwebtoken');

async function testUpdate() {
  try {
    // Generate an admin token
    const token = 'dummy_access_token_admin_12345';
    
    // First, list tournaments to get an ID
    const listRes = await axios.get('http://localhost:3000/api/admin/tournaments', {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    const tournaments = listRes.data.data;
    if (tournaments.length === 0) {
      console.log('No tournaments found to update.');
      return;
    }
    
    const t = tournaments[0];
    console.log('Updating tournament ID:', t.id);
    
    // Attempt to update with typical payload from frontend
    const payload = {
      name: t.name,
      description: 'Updated via script',
      max_participants: 500,
      entry_fee_paise: 0,
      rules: '',
      starts_at: new Date(Date.now() + 86400000).toISOString(),
    };
    
    console.log('Sending payload:', payload);
    const updateRes = await axios.put(`http://localhost:3000/api/tournaments/${t.id}`, payload, {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    console.log('Update success:', updateRes.data);
  } catch (error) {
    if (error.response) {
      console.error('Update failed. Status:', error.response.status);
      console.error('Data:', JSON.stringify(error.response.data, null, 2));
    } else {
      console.error('Update failed:', error.message);
    }
  }
}

testUpdate();
