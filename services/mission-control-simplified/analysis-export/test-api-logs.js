const { callNicheScout } = require('./integrate-with-social-intel');
const util = require('util');

async function testApiWithLogs() {
  console.log('DETAILED API TEST WITH LOGGING');
  console.log('==============================');
  
  try {
    console.log('Making API call to niche-scout with test parameters...');
    const result = await callNicheScout({
      query: 'mobile',
      category: 'Gaming',
      subcategories: ['Mobile Gaming']
    });
    
    console.log('\nAPI CALL RESPONSE:');
    console.log('==================');
    console.log(util.inspect(result, { depth: null, colors: true }));
    
    console.log('\nVERIFYING DATA SOURCE:');
    console.log('====================');
    console.log('Is mock data:', result._mock ? 'Yes' : 'No');
    console.log('Query parameter returned by API:', result.query);
    console.log('Category parameter returned by API:', result.category);
    
    if (result.query === null && result.category === null) {
      console.log('\nCONCLUSION: The API ignored our parameters but our client-side filtering was NOT applied.');
    } else if (result.query === 'mobile' && result.category === 'Gaming') {
      console.log('\nCONCLUSION: Our client-side filtering successfully applied search parameters.');
      
      // Print the implementation details
      console.log('\nIMPLEMENTATION DETAILS:');
      console.log('======================');
      if (result._filtered) {
        console.log('Client-side filtering was applied to the API results.');
      } else {
        console.log('API returned correctly filtered results directly (unlikely).');
      }
    }
    
    // Check niches for relevance
    console.log('\nRELEVANCE CHECK:');
    console.log('===============');
    const relevantNiches = result.niches.filter(niche => 
      niche.name.toLowerCase().includes('gaming') || 
      niche.name.toLowerCase().includes('mobile')
    );
    
    console.log(`Found ${relevantNiches.length} out of ${result.niches.length} niches related to gaming or mobile`);
    
    // Log each niche and its relevance
    console.log('\nNICHE RELEVANCE DETAILS:');
    result.niches.forEach((niche, index) => {
      const isRelevant = niche.name.toLowerCase().includes('gaming') || 
                         niche.name.toLowerCase().includes('mobile');
      console.log(`Niche ${index+1}: "${niche.name}" - Relevant: ${isRelevant ? 'Yes' : 'No'}`);
    });
    
    // Analyze trending topics
    console.log('\nTRENDING TOPICS ANALYSIS:');
    console.log('=======================');
    if (result.niches && result.niches.length > 0) {
      result.niches.forEach((niche, index) => {
        console.log(`Niche: ${niche.name}`);
        if (niche.trending_topics) {
          console.log(`  Topics: ${niche.trending_topics.join(', ')}`);
        } else {
          console.log('  No trending topics available');
        }
      });
    }
    
    // Check if we have analysis from the API
    console.log('\nAPI ANALYSIS SUMMARY:');
    console.log('====================');
    if (result.analysis_summary) {
      console.log(util.inspect(result.analysis_summary, { depth: null, colors: true }));
    } else {
      console.log('No analysis summary provided by the API');
    }
    
  } catch (error) {
    console.error('Error during test:', error);
  }
}

testApiWithLogs();