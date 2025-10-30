const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs').promises;
const crypto = require('crypto');

const app = express();
const PORT = 3001;

// Configuration
const UPLOAD_DIR = '/home/ian/photo-portfolio/uploads';
const CHUNK_DIR = '/home/ian/photo-portfolio/chunks';
const MAX_FILE_SIZE = 50 * 1024 * 1024; // 50MB
const CHUNK_SIZE = 1024 * 1024; // 1MB

// Ensure directories exist
async function ensureDirectories() {
    try {
        await fs.mkdir(UPLOAD_DIR, { recursive: true });
        await fs.mkdir(CHUNK_DIR, { recursive: true });
        console.log('✅ Upload directories created/verified');
    } catch (error) {
        console.error('❌ Error creating directories:', error);
    }
}

// Initialize directories
ensureDirectories();

// Middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// CORS middleware for development
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization, X-Upload-Source');
    
    if (req.method === 'OPTIONS') {
        res.sendStatus(200);
    } else {
        next();
    }
});

// Configure multer for chunked uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, CHUNK_DIR);
    },
    filename: (req, file, cb) => {
        // Generate unique filename for chunk
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, `chunk-${uniqueSuffix}-${file.originalname}`);
    }
});

const upload = multer({ 
    storage: storage,
    limits: {
        fileSize: MAX_FILE_SIZE
    },
    fileFilter: (req, file, cb) => {
        // Allow only image files
        const allowedTypes = /jpeg|jpg|png|gif|webp|tiff|bmp/;
        const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
        const mimetype = allowedTypes.test(file.mimetype);
        
        if (mimetype && extname) {
            return cb(null, true);
        } else {
            cb(new Error('Only image files are allowed!'));
        }
    }
});

// Helper function to combine chunks
async function combineChunks(chunkFiles, outputPath) {
    try {
        console.log(`🔗 Combining ${chunkFiles.length} chunks into ${outputPath}`);
        
        const writeStream = require('fs').createWriteStream(outputPath);
        
        for (const chunkFile of chunkFiles) {
            const chunkPath = path.join(CHUNK_DIR, chunkFile);
            const chunkData = await fs.readFile(chunkPath);
            writeStream.write(chunkData);
            
            // Clean up chunk file
            await fs.unlink(chunkPath);
        }
        
        writeStream.end();
        
        return new Promise((resolve, reject) => {
            writeStream.on('finish', () => {
                console.log(`✅ Successfully combined chunks into ${outputPath}`);
                resolve();
            });
            writeStream.on('error', reject);
        });
    } catch (error) {
        console.error('❌ Error combining chunks:', error);
        throw error;
    }
}

// Helper function to get file info
async function getFileInfo(filePath) {
    try {
        const stats = await fs.stat(filePath);
        return {
            size: stats.size,
            created: stats.birthtime,
            modified: stats.mtime
        };
    } catch (error) {
        console.error('❌ Error getting file info:', error);
        return null;
    }
}

// Upload endpoint for chunked uploads
app.post('/api/upload', upload.single('file'), async (req, res) => {
    try {
        const startTime = Date.now();
        
        if (!req.file) {
            return res.status(400).json({ 
                error: 'No file uploaded',
                success: false 
            });
        }

        const { originalname, filename, size, mimetype } = req.file;
        const chunkPath = path.join(CHUNK_DIR, filename);
        
        console.log(`📤 Received chunk: ${originalname} (${size} bytes)`);
        
        // For single file uploads (non-chunked)
        if (!req.body.chunkNumber || !req.body.totalChunks) {
            // Move file directly to uploads directory
            const finalPath = path.join(UPLOAD_DIR, originalname);
            await fs.rename(chunkPath, finalPath);
            
            const fileInfo = await getFileInfo(finalPath);
            const uploadTime = Date.now() - startTime;
            
            console.log(`✅ Single file upload complete: ${originalname}`);
            
            return res.json({
                success: true,
                message: 'File uploaded successfully',
                file: {
                    name: originalname,
                    size: size,
                    path: finalPath,
                    uploadTime: uploadTime,
                    ...fileInfo
                }
            });
        }
        
        // For chunked uploads
        const chunkNumber = parseInt(req.body.chunkNumber);
        const totalChunks = parseInt(req.body.totalChunks);
        const fileId = req.body.fileId || crypto.createHash('md5').update(originalname).digest('hex');
        
        console.log(`📦 Chunk ${chunkNumber + 1}/${totalChunks} for ${originalname}`);
        
        // Check if this is the last chunk
        if (chunkNumber === totalChunks - 1) {
            // Find all chunks for this file
            const chunkFiles = [];
            for (let i = 0; i < totalChunks; i++) {
                const chunkFilename = `${fileId}-chunk-${i}`;
                const chunkPath = path.join(CHUNK_DIR, chunkFilename);
                
                try {
                    await fs.access(chunkPath);
                    chunkFiles.push(chunkFilename);
                } catch (error) {
                    console.error(`❌ Missing chunk: ${chunkFilename}`);
                    return res.status(400).json({
                        error: `Missing chunk ${i}`,
                        success: false
                    });
                }
            }
            
            // Combine chunks
            const finalPath = path.join(UPLOAD_DIR, originalname);
            await combineChunks(chunkFiles, finalPath);
            
            const fileInfo = await getFileInfo(finalPath);
            const uploadTime = Date.now() - startTime;
            
            console.log(`✅ Chunked upload complete: ${originalname} (${totalChunks} chunks)`);
            
            return res.json({
                success: true,
                message: 'File uploaded successfully',
                file: {
                    name: originalname,
                    size: fileInfo.size,
                    path: finalPath,
                    chunks: totalChunks,
                    uploadTime: uploadTime,
                    ...fileInfo
                }
            });
        } else {
            // Rename chunk to include file ID and chunk number
            const newChunkName = `${fileId}-chunk-${chunkNumber}`;
            const newChunkPath = path.join(CHUNK_DIR, newChunkName);
            await fs.rename(chunkPath, newChunkPath);
            
            return res.json({
                success: true,
                message: `Chunk ${chunkNumber + 1}/${totalChunks} received`,
                chunkNumber: chunkNumber,
                totalChunks: totalChunks
            });
        }
        
    } catch (error) {
        console.error('❌ Upload error:', error);
        res.status(500).json({
            error: error.message,
            success: false
        });
    }
});

// Get upload statistics
app.get('/api/upload-stats', async (req, res) => {
    try {
        const files = await fs.readdir(UPLOAD_DIR);
        let totalSize = 0;
        let totalFiles = files.length;
        
        for (const file of files) {
            const filePath = path.join(UPLOAD_DIR, file);
            const stats = await fs.stat(filePath);
            totalSize += stats.size;
        }
        
        res.json({
            totalFiles: totalFiles,
            totalSize: totalSize,
            totalSizeMB: (totalSize / 1024 / 1024).toFixed(2),
            uploadDir: UPLOAD_DIR
        });
    } catch (error) {
        console.error('❌ Error getting upload stats:', error);
        res.status(500).json({ error: error.message });
    }
});

// List uploaded files
app.get('/api/uploads', async (req, res) => {
    try {
        const files = await fs.readdir(UPLOAD_DIR);
        const fileList = [];
        
        for (const file of files) {
            const filePath = path.join(UPLOAD_DIR, file);
            const stats = await fs.stat(filePath);
            fileList.push({
                name: file,
                size: stats.size,
                sizeMB: (stats.size / 1024 / 1024).toFixed(2),
                created: stats.birthtime,
                modified: stats.mtime
            });
        }
        
        res.json({
            files: fileList,
            count: fileList.length
        });
    } catch (error) {
        console.error('❌ Error listing uploads:', error);
        res.status(500).json({ error: error.message });
    }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        uploadDir: UPLOAD_DIR,
        chunkDir: CHUNK_DIR
    });
});

// Error handling middleware
app.use((error, req, res, next) => {
    console.error('❌ Server error:', error);
    res.status(500).json({
        error: error.message,
        success: false
    });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Uppy.js Upload Server running on port ${PORT}`);
    console.log(`📁 Upload directory: ${UPLOAD_DIR}`);
    console.log(`📦 Chunk directory: ${CHUNK_DIR}`);
    console.log(`🌐 Server URL: http://192.168.50.243:${PORT}`);
    console.log(`📤 Upload endpoint: http://192.168.50.243:${PORT}/api/upload`);
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\n🛑 Shutting down upload server...');
    process.exit(0);
});

process.on('SIGTERM', () => {
    console.log('\n🛑 Shutting down upload server...');
    process.exit(0);
});

