import axios from 'axios';
import * as cheerio from 'cheerio';

const BEARER_TOKEN = 'dynamic-token';
const BASE_URL = 'https://www.firme.info/medicina/psihologie/pagina_lista_firme_{PAGE}.html';
const API_URL = 'https://api.e-cui.ro/v1/companies/';

async function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function scrapePage(pageNumber) {
    try {
        const url = BASE_URL.replace('{PAGE}', pageNumber.toString());
        console.log(`🔍 Accesare URL: ${url}`);
        
        const response = await axios.get(url);
        const $ = cheerio.load(response.data);
        const cuis = [];

        // Selectăm toate rândurile din tbody
        $('table.table-striped tbody tr').each((_, element) => {
            // Extragem textul din celula CUI și curățăm spațiile
            const cuiText = $(element).find('td:nth-child(2)').text().trim();
            
            // Folosim regex pentru a extrage doar numerele
            const cuiMatch = cuiText.match(/\d+/);
            
            if (cuiMatch) {
                const cui = cuiMatch[0];
                if (cui.length >= 6 && cui.length <= 9) { // CUI-urile valide au între 6 și 9 cifre
                    console.log(`🔎 CUI găsit: ${cui}`);
                    cuis.push(cui);
                }
            }
        });

        console.log(`📊 Total CUI-uri găsite pe pagina ${pageNumber}: ${cuis.length}`);
        return cuis;
    } catch (error) {
        console.error(`❌ Eroare la pagina ${pageNumber}:`, error.message);
        return [];
    }
}

async function processCUI(cui) {
    try {
        await sleep(2000); // Delay între requesturi

        // Curățăm CUI-ul de spații și caractere nedorite
        const cleanCui = cui.trim().replace(/\s+/g, '');
        
        const response = await axios.get(`${API_URL}${cleanCui}`, {
            headers: {
                'Authorization': `Bearer ${BEARER_TOKEN}`,
                'Accept': 'application/json'
            }
        });

        console.log(`✅ CUI procesat cu succes: ${cleanCui}`);
        return true;
    } catch (error) {
        if (error.response?.status === 500) {
            console.log(`⚠️ CUI ${cui} nu a fost găsit în baza de date`);
        } else {
            console.error(`❌ Eroare la procesarea CUI ${cui}:`, error.message);
        }
        return false;
    }
}

async function main() {
    const startPage = 1;
    const endPage = 72;
    const results = {
        success: 0,
        failed: 0,
        cuis: []
    };

    console.log('🚀 Începe procesul de scraping...\n');

    for (let page = startPage; page <= endPage; page++) {
        console.log(`\n📄 Procesare pagina ${page}...`);
        const cuis = await scrapePage(page);
        
        if (cuis.length === 0) {
            console.log(`⚠️ Nu s-au găsit CUI-uri pe pagina ${page}`);
            continue;
        }

        results.cuis.push(...cuis);

        for (const cui of cuis) {
            const success = await processCUI(cui);
            if (success) {
                results.success++;
            } else {
                results.failed++;
            }
        }

        console.log(`\n✨ Pagina ${page} completă. Progres: ${results.success + results.failed}/${results.cuis.length}`);
        await sleep(2000);
    }

    console.log('\n📊 Rezultate finale:');
    console.log(`Total CUI-uri găsite: ${results.cuis.length}`);
    console.log(`Procesate cu succes: ${results.success}`);
    console.log(`Eșuate: ${results.failed}`);
}

main().catch(console.error); 