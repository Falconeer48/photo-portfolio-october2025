import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Function to convert folder name to title case and format
function formatTitle(folderName) {
  return folderName
    .split('_')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

// Function to generate a description based on the title
function generateDescription(title) {
  return `Collection of ${title.toLowerCase()} photographs`;
}

// Function to check if a directory has images
async function hasImages(dirPath) {
  try {
    const files = await fs.readdir(dirPath);
    return files.some(file => /\.(jpg|jpeg|png|gif)$/i.test(file));
  } catch (error) {
    console.error('Error checking for images:', error);
    return false;
  }
}

// Function to process a directory and its subdirectories
async function processDirectory(dirPath, parentPath = '') {
  const categories = [];
  const entries = await fs.readdir(dirPath);

  for (const entry of entries) {
    if (entry.startsWith('.')) continue; // Skip hidden files
    if (entry === 'optimized' || entry === 'portfolio') continue; // Skip optimized and portfolio directories

    const fullPath = join(dirPath, entry);
    const stats = await fs.stat(fullPath);

    if (stats.isDirectory()) {
      const relativePath = parentPath ? `${parentPath}/${entry}` : entry;
      const hasImagesInDir = await hasImages(fullPath);
      
      // Create category for current directory if it has images
      if (hasImagesInDir) {
        categories.push({
          id: relativePath.toLowerCase().replace(/[^a-z0-9]+/g, '-'),
          title: formatTitle(entry),
          description: generateDescription(formatTitle(entry)),
          folder: relativePath,
          featured: parentPath === '', // Only top-level galleries are featured
          parent: parentPath || null
        });
      }

      // Process subdirectories
      const subCategories = await processDirectory(fullPath, relativePath);
      categories.push(...subCategories);
    }
  }

  return categories;
}

export async function generatePortfolioConfig() {
  try {
    // Use environment variable for portfolio path, fallback to local path
    const portfolioPath = process.env.PORTFOLIO_PATH || join(__dirname, '../../public/images/portfolio');
    const categories = await processDirectory(portfolioPath);

    // Sort categories: featured (top-level) first, then alphabetically
    categories.sort((a, b) => {
      if (a.featured !== b.featured) return b.featured ? 1 : -1;
      return a.title.localeCompare(b.title);
    });

    return categories;
  } catch (error) {
    console.error('Error generating portfolio config:', error);
    return [];
  }
} 