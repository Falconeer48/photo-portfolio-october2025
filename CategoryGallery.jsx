/** @jsxImportSource @emotion/react */
import { useState, useEffect } from 'react'
import styled from '@emotion/styled'
import CommentThread from './CommentThread'
import OptimizedImage from './OptimizedImage'

const GalleryContainer = styled.div`
  padding: 2rem;
  max-width: 1200px;
  margin: 0 auto;
`

const GalleryHeader = styled.div`
  margin-bottom: 2rem;
  text-align: center;
`

const GalleryTitle = styled.h2`
  font-size: 2.5rem;
  color: #333;
  margin-bottom: 0.5rem;
`

const GalleryDescription = styled.p`
  color: #666;
  font-size: 1.1rem;
`

const BackButton = styled.button`
  background: none;
  border: none;
  color: #333;
  font-size: 1rem;
  cursor: pointer;
  padding: 0.5rem 1rem;
  margin-bottom: 1rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;

  &:hover {
    color: #000;
  }
`

const ImageGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  gap: 1rem;
  padding: 2rem;
  max-width: 1400px;
  margin: 0 auto;

  @media (max-width: 1200px) {
    grid-template-columns: repeat(4, 1fr);
  }

  @media (max-width: 900px) {
    grid-template-columns: repeat(3, 1fr);
  }

  @media (max-width: 600px) {
    grid-template-columns: repeat(2, 1fr);
  }
`

const ImageContainer = styled.div`
  position: relative;
  cursor: pointer;
  background: white;
  padding: 8px;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
  overflow: hidden;
  grid-column: span ${props => props.size || 2};
  grid-row: span ${props => props.size || 2};

  &:nth-of-type(6n+1) {
    grid-column: span 3;
    grid-row: span 3;
  }

  &:nth-of-type(6n+4) {
    grid-column: span 2;
    grid-row: span 3;
  }

  &:hover {
    transform: translateY(-4px);
    box-shadow: 0 8px 12px rgba(0,0,0,0.15);
  }

  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    border-radius: 4px;
  }
`



const BackToTopButton = styled.button`
  position: fixed;
  bottom: 30px;
  right: 30px;
  width: 50px;
  height: 50px;
  border-radius: 50%;
  background: rgba(26, 35, 126, 0.9);
  color: white;
  border: none;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.5rem;
  box-shadow: 0 4px 12px rgba(0,0,0,0.3);
  transition: all 0.3s ease;
  z-index: 1000;
  opacity: 0.7;
  transform: translateY(20px);
  pointer-events: none;

  &.visible {
    opacity: 1;
    transform: translateY(0);
    pointer-events: auto;
  }

  &:hover {
    background: rgba(26, 35, 126, 1);
    transform: translateY(-2px);
    box-shadow: 0 6px 16px rgba(0,0,0,0.4);
  }

  &:active {
    transform: translateY(0);
  }

  @media (max-width: 768px) {
    bottom: 20px;
    right: 20px;
    width: 45px;
    height: 45px;
    font-size: 1.3rem;
  }
`

const Image = styled.img`
  width: 100%;
  height: auto;
  display: block;
  border-radius: 4px;
  transition: transform 0.3s ease;
  border: 8px solid white;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
`

const ErrorMessage = styled.div`
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  color: #666;
  text-align: center;
`

const FullscreenOverlay = styled.div`
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: black;
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
  cursor: zoom-out;
  
  /* Mobile optimizations */
  @media (max-width: 768px) {
    /* Hide browser UI on mobile */
    height: 100vh;
    height: 100dvh; /* Dynamic viewport height for mobile */
    width: 100vw;
    width: 100dvw; /* Dynamic viewport width for mobile */
    
    /* Prevent scrolling */
    overflow: hidden;
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    
    /* Touch-friendly - fully managed by JS to avoid accidental scroll/back swipe */
    touch-action: none;
  }
  
  /* Landscape orientation fixes */
  @media (max-width: 768px) and (orientation: landscape) {
    /* Full screen in landscape - use ALL available space */
    height: 100vh !important;
    height: 100dvh !important;
    width: 100vw;
    width: 100dvw;
    /* Center the image vertically and horizontally */
    align-items: center;
    justify-content: center;
    /* No padding - use full viewport */
    padding: 0;
    box-sizing: border-box;
  }
  
  /* True fullscreen mode - completely clean */
  &:fullscreen {
    background: black;
  }
`

const FullscreenImage = styled.img`
  max-width: 98vw;
  max-height: 95vh;
  width: auto;
  height: auto;
  object-fit: contain;
  border-radius: 4px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
  cursor: default;
  transition: transform 0.3s ease;
  border: 8px solid white;
  background: white;
  margin-top: -40px;
  
  /* Dynamic sizing based on screen dimensions */
  @supports (width: 100vw) {
    max-width: min(98vw, calc(100vw - 16px));
    max-height: min(95vh, calc(100vh - 16px));
  }
  
  /* Mobile optimizations - keep white border */
  @media (max-width: 768px) {
    /* Keep white border but adjust size */
    border: 4px solid white;
    border-radius: 4px;
    margin-top: 0;
    
    /* Use almost full viewport with dynamic sizing */
    max-width: min(98vw, calc(100vw - 8px));
    max-width: min(98dvw, calc(100dvw - 8px));
    max-height: min(95vh, calc(100vh - 8px));
    max-height: min(95dvh, calc(100dvh - 8px));
    
    /* Better image quality */
    image-rendering: -webkit-optimize-contrast;
    image-rendering: crisp-edges;
  }
  
  /* Landscape orientation */
  @media (max-width: 768px) and (orientation: landscape) {
    /* Use full viewport in landscape - controls hidden, so maximize space */
    max-height: 100vh !important;
    max-height: 100dvh !important;
    max-width: 100vw !important;
    max-width: 100dvw !important;
    width: auto;
    height: auto;
    object-fit: contain;
    /* Center the image */
    margin: 0;
    border: 2px solid white;
  }
  
  /* Portrait orientation */
  @media (max-width: 768px) and (orientation: portrait) {
    /* Full screen in portrait with border */
    max-width: min(98vw, calc(100vw - 8px));
    max-width: min(98dvw, calc(100dvw - 8px));
    max-height: min(95vh, calc(100vh - 8px));
    max-height: min(95dvh, calc(100dvh - 8px));
    object-fit: contain;
  }
`

const FullscreenControls = styled.div`
  position: fixed;
  bottom: 10px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  gap: 0.3rem;
  z-index: 1001;
  background: rgba(0, 0, 0, 0.6);
  padding: 4px;
  border-radius: 6px;
  backdrop-filter: blur(10px);
  opacity: 0.8;
  transition: opacity 0.2s ease;
  justify-content: center;
  align-items: center;
  flex-wrap: nowrap;
  max-width: 95vw;
  overflow-x: auto;

  &:hover {
    opacity: 1;
  }
  
  /* Mobile optimizations */
  @media (max-width: 768px) {
    bottom: 5px;
    padding: 2px;
    gap: 0.1rem;
    opacity: 0.9;
    max-width: 98vw;
    
    /* Auto-hide on mobile after 3 seconds */
    animation: fadeInOut 3s ease-in-out;
  }
  
  /* Extra small screens */
  @media (max-width: 480px) {
    bottom: 3px;
    padding: 2px;
    gap: 0.1rem;
    max-width: 98vw;
  }
  
  /* Hide controls in landscape on mobile to maximize image space */
  @media (max-width: 768px) and (orientation: landscape) {
    display: none !important;
  }
  
  @keyframes fadeInOut {
    0% { opacity: 0.9; }
    50% { opacity: 0.9; }
    100% { opacity: 0.3; }
  }
`

const ControlButton = styled.button`
  background: rgba(255, 255, 255, 0.15);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: white;
  padding: 5px 6px;
  border-radius: 3px;
  cursor: pointer;
  font-size: 0.7rem;
  display: flex;
  align-items: center;
  gap: 3px;
  transition: all 0.2s ease;
  white-space: nowrap;
  min-width: fit-content;
  
  &:hover {
    background: rgba(255, 255, 255, 0.25);
    transform: translateY(-1px);
  }

  &:active {
    transform: translateY(0);
    background: rgba(255, 255, 255, 0.3);
  }
  
  /* Better touch feedback for mobile */
  @media (max-width: 768px) {
    padding: 4px 5px;
    font-size: 0.65rem;
    gap: 2px;
    
    &:active {
      background: rgba(255, 255, 255, 0.4);
      transform: scale(0.95);
    }
  }
  
  /* Show/hide text based on screen size */
  .desktop-text {
    display: inline;
  }
  
  .mobile-text {
    display: none;
  }
  
  /* Mobile optimizations - buttons for iPhone (15% smaller) */
  @media (max-width: 768px) {
    padding: 2px 4px !important;
    font-size: 0.6rem !important;
    gap: 1px !important;
    min-height: 30px !important;
    border-radius: 3px !important;
    min-width: 30px !important;
    
    .desktop-text {
      display: none !important;
    }
    
    .mobile-text {
      display: inline !important;
    }
  }
  
  /* Extra small for very small screens (15% smaller) */
  @media (max-width: 480px) {
    padding: 1px 3px !important;
    font-size: 0.55rem !important;
    gap: 0.5px !important;
    min-height: 26px !important;
    min-width: 26px !important;
  }
`

const CloseButton = styled.button`
  position: fixed;
  top: 20px;
  right: 20px;
  background: rgba(0, 0, 0, 0.6);
  border: none;
  color: white;
  font-size: 2rem;
  cursor: pointer;
  z-index: 1001;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  
  &:hover {
    background: rgba(255, 255, 255, 0.2);
    transform: scale(1.1);
  }
  
  /* Mobile optimizations */
  @media (max-width: 768px) {
    top: 10px;
    right: 10px;
    width: 35px;
    height: 35px;
    font-size: 1.5rem;
  }
`



const ImageCounter = styled.div`
  position: fixed;
  top: 20px;
  left: 50%;
  transform: translateX(-50%);
  color: white;
  font-size: 0.9rem;
  background: rgba(0, 0, 0, 0.6);
  padding: 8px 12px;
  border-radius: 4px;
  z-index: 1001;
  
  /* Mobile optimizations */
  @media (max-width: 768px) {
    top: 10px;
    font-size: 0.8rem;
    padding: 6px 10px;
  }
`


const ImageTitle = styled.div`
  position: absolute;
  bottom: 120px;
  left: 50%;
  transform: translateX(-50%);
  color: white;
  font-size: 1.2rem;
  font-weight: 500;
  background: rgba(0, 0, 0, 0.8);
  padding: 12px 16px;
  border-radius: 8px;
  z-index: 999;
  text-align: center;
  word-wrap: break-word;
  backdrop-filter: blur(10px);
  text-shadow: 0 1px 3px rgba(0, 0, 0, 0.8);
  max-width: 80%;
  pointer-events: none;
`

const SwipeIndicator = styled.div`
  position: fixed;
  bottom: 60px;
  left: 50%;
  transform: translateX(-50%);
  color: rgba(255, 255, 255, 0.8);
  font-size: 0.8rem;
  text-align: center;
  z-index: 1001;
  pointer-events: none;
  animation: fadeInOut 4s ease-in-out;
  background: rgba(0, 0, 0, 0.5);
  padding: 8px 12px;
  border-radius: 6px;
  backdrop-filter: blur(5px);
  
  @keyframes fadeInOut {
    0% { opacity: 0.7; }
    15% { opacity: 1; }
    85% { opacity: 1; }
    100% { opacity: 0.7; }
  }
  
  /* Only show on mobile */
  @media (min-width: 769px) {
    display: none;
  }
  
  /* Extra small screens */
  @media (max-width: 480px) {
    bottom: 50px;
    font-size: 0.7rem;
    padding: 6px 10px;
  }
`

const TitleEditOverlay = styled.div`
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1002;
`

const TitleEditInput = styled.input`
  background: white;
  border: 2px solid #1a237e;
  border-radius: 8px;
  padding: 1rem 1.5rem;
  font-size: 1.2rem;
  width: 80%;
  max-width: 500px;
  outline: none;
  
  &:focus {
    border-color: #4CAF50;
    box-shadow: 0 0 0 3px rgba(76, 175, 80, 0.2);
  }
`

const ImageInfo = styled.div`
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  background: rgba(0, 0, 0, 0.7);
  color: white;
  padding: 0.5rem;
  font-size: 0.8rem;
  opacity: 0.7;
  transition: opacity 0.3s ease;
  
  ${ImageContainer}:hover & {
    opacity: 1;
  }
`

const RefreshButton = styled.button`
  background: #4CAF50;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  cursor: pointer;
  margin-bottom: 1rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  
  &:hover {
    background: #45a049;
  }
`

const SubcategoryGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
  margin-top: 2rem;
  padding: 1rem;
  background: rgba(0, 0, 0, 0.03);
  border-radius: 8px;
`

const SubcategoryCard = styled.div`
  background: white;
  padding: 1rem;
  border-radius: 8px;
  cursor: pointer;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  transition: transform 0.2s ease;

  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0,0,0,0.15);
  }
`

const SubcategoryTitle = styled.h3`
  font-size: 1.2rem;
  color: #333;
  margin: 0;
  margin-bottom: 0.5rem;
`

const SubcategoryDescription = styled.p`
  font-size: 0.9rem;
  color: #666;
  margin: 0;
`

const DownloadButton = styled.button`
  position: absolute;
  top: 10px;
  right: 10px;
  background: rgba(255, 255, 255, 0.9);
  border: none;
  border-radius: 4px;
  padding: 6px 12px;
  font-size: 0.9rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 4px;
  opacity: 0.7;
  transition: opacity 0.2s ease;
  z-index: 2;
  color: #333;
  
  &:hover {
    background: white;
  }

  ${ImageContainer}:hover & {
    opacity: 1;
  }
`

const FullscreenDownloadButton = styled.button`
  position: fixed;
  top: 20px;
  right: 80px;
  background: rgba(0, 0, 0, 0.6);
  border: none;
  color: white;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.9rem;
  z-index: 1001;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: all 0.2s ease;
  
  background: rgba(0, 0, 0, 0.7);
  color: white;
  padding: 0.5rem;
  font-size: 0.9rem;
  opacity: 0.7;
  transition: opacity 0.3s ease;
  max-height: 60px;
  overflow-y: auto;
  
  ${ImageContainer}:hover & {
    opacity: 1;
  }
`

const CommentEditArea = styled.div`
  position: fixed;
  bottom: 80px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(0, 0, 0, 0.8);
  padding: 20px;
  border-radius: 8px;
  z-index: 1001;
  width: 80%;
  max-width: 600px;
`

function formatDate(dateString) {
  const date = new Date(dateString)
  return date.toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const downloadImage = async (imageUrl, filename) => {
  try {
    const response = await fetch(imageUrl);
    const blob = await response.blob();
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);
  } catch (error) {
    console.error('Error downloading image:', error);
    alert('Failed to download image. Please try again.');
  }
};

function getOptimalImageSrc(originalSrc, isFullscreen = false) {
  // Get screen dimensions
  const screenWidth = window.screen.width;
  const screenHeight = window.screen.height;
  const pixelRatio = window.devicePixelRatio || 1;
  
  // Calculate effective resolution
  const effectiveWidth = screenWidth * pixelRatio;
  const effectiveHeight = screenHeight * pixelRatio;
  
  // Detect mobile devices more accurately
  const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) || 
                   screenWidth <= 768 || 
                   (screenWidth <= 1024 && screenHeight <= 768);
  
  // Determine optimal size based on device and context
  let optimalSize = 'previews'; // Default: 800x800px
  
  if (isFullscreen) {
    // For fullscreen, always use full resolution for maximum quality
    // This ensures large screens get the best image quality
    optimalSize = 'full';
  } else {
    // For gallery thumbnails, use smaller sizes to save bandwidth
    if (isMobile) {
      // Mobile thumbnails: use even smaller images
      optimalSize = 'thumbnails'; // 300x300px for faster loading
    } else if (effectiveWidth >= 2560 || effectiveHeight >= 1440) {
      // 4K or high-DPI displays
      optimalSize = 'large';
    } else if (effectiveWidth >= 1920 || effectiveHeight >= 1080) {
      // Full HD displays
      optimalSize = 'large';
    } else if (effectiveWidth >= 1366 || effectiveHeight >= 768) {
      // HD displays
      optimalSize = 'previews';
    } else {
      // Small desktop
      optimalSize = 'previews';
    }
  }
  
  // Replace path to get optimized version
  let optimizedSrc;
  if (optimalSize === 'full') {
    // For full resolution, use the full subfolder (original quality)
    optimizedSrc = originalSrc.replace('/images/portfolio/', '/images/optimized/full/');
  } else {
    // For other sizes, use the size subfolder
    optimizedSrc = originalSrc.replace('/images/portfolio/', `/images/optimized/${optimalSize}/`);
  }
  
  // URL-encode the path to handle spaces and special characters in folder/file names
  // Split the path into parts and encode each component
  const urlParts = optimizedSrc.split('/');
  const encodedParts = urlParts.map(part => {
    if (part === 'images' || part === 'optimized' || optimalSize === 'full' || ['thumbnails', 'previews', 'large', 'mobile', 'full'].includes(part)) {
      // Don't encode the route segments
      return part;
    }
    // Encode the actual folder/file names
    return encodeURIComponent(part);
  });
  optimizedSrc = encodedParts.join('/');
  
  // Debug logging for mobile devices
  if (isMobile) {
    console.log(`📱 Mobile device detected: ${screenWidth}x${screenHeight}, pixelRatio: ${pixelRatio}`);
    console.log(`📱 Loading image: ${optimalSize} size for ${isFullscreen ? 'fullscreen' : 'thumbnail'}`);
    console.log(`📱 Image path: ${optimizedSrc}`);
  }
  
  return optimizedSrc;
}

function GalleryImage({ image, onClick, index }) {
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)
  const filename = image.src.split('/').pop()

  // Helper function to safely render comment text
  const getCommentText = (comment) => {
    if (!comment) return '';
    if (typeof comment === 'string') return comment;
    return comment.text || '';
  }



  return (
    <ImageContainer onClick={() => onClick(image)}>
      {error ? (
        <ErrorMessage>Unable to load image</ErrorMessage>
      ) : (
        <>
          <Image
            src={getOptimalImageSrc(image.src)}
            alt={image.alt}
            onLoad={() => setLoading(false)}
            onError={(e) => {
              console.error('Failed to load optimized image, trying fallbacks:', image.src)
              const img = e.target;
              const currentSrc = img.src;
              
              // Try fallback order: large -> previews -> original
              if (currentSrc.includes('/optimized/full/')) {
                // Try large if full fails
                img.src = currentSrc.replace('/optimized/full/', '/optimized/large/');
              } else if (currentSrc.includes('/optimized/large/')) {
                // Try previews if large fails
                img.src = currentSrc.replace('/optimized/large/', '/optimized/previews/');
              } else if (currentSrc.includes('/optimized/previews/')) {
                // Fallback to original if all optimized versions fail
                img.src = image.src;
              } else {
                // Already at original, give up
                setError(true);
              }
            }}
          />
          {image.comment && (
            <ImageComment>{getCommentText(image.comment)}</ImageComment>
          )}

        </>
      )}
    </ImageContainer>
  )
}

function CategoryGallery({ category, subcategories = [], onBack, onSubcategoryClick, isAdmin = false, parentCategory = null }) {
  const [images, setImages] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [selectedImage, setSelectedImage] = useState(null)
  const [isSlideshow, setIsSlideshow] = useState(false)
  const [slideshowInterval, setSlideshowInterval] = useState(null)
  const [refreshKey, setRefreshKey] = useState(0)
  const [isZoomed, setIsZoomed] = useState(false)
  const [editingComment, setEditingComment] = useState('')
  const [isEditingComment, setIsEditingComment] = useState(false)
  const [comments, setComments] = useState([])
  const [showTitle, setShowTitle] = useState(false)
  const [editingTitle, setEditingTitle] = useState(false)
  const [titleText, setTitleText] = useState('')
  const [isFullscreen, setIsFullscreen] = useState(false)
  const [showBackToTop, setShowBackToTop] = useState(false)
  const [touchStart, setTouchStart] = useState(null)
  const [touchEnd, setTouchEnd] = useState(null)
  const [touchStartPos, setTouchStartPos] = useState(null)
  const [touchCurrentPos, setTouchCurrentPos] = useState(null)
  const [pinchStart, setPinchStart] = useState(null)
  const [screenSize, setScreenSize] = useState({ width: 0, height: 0 })
  
  // Screen size detection for dynamic image sizing
  useEffect(() => {
    const updateScreenSize = () => {
      setScreenSize({
        width: window.innerWidth,
        height: window.innerHeight
      })
    }
    
    // Initial size
    updateScreenSize()
    
    // Update on resize
    window.addEventListener('resize', updateScreenSize)
    window.addEventListener('orientationchange', updateScreenSize)
    
    return () => {
      window.removeEventListener('resize', updateScreenSize)
      window.removeEventListener('orientationchange', updateScreenSize)
    }
  }, [])

  // Simple fullscreen state tracking (no rotation handling)
  useEffect(() => {
    const handleFullscreenChange = () => {
      const isNowFullscreen = !!document.fullscreenElement
      setIsFullscreen(isNowFullscreen)
    }

    // Check initial fullscreen state
    setIsFullscreen(!!document.fullscreenElement)

    // Add fullscreen change listeners
    document.addEventListener('fullscreenchange', handleFullscreenChange)
    document.addEventListener('webkitfullscreenchange', handleFullscreenChange)
    document.addEventListener('mozfullscreenchange', handleFullscreenChange)
    document.addEventListener('MSFullscreenChange', handleFullscreenChange)
    
    return () => {
      document.removeEventListener('fullscreenchange', handleFullscreenChange)
      document.removeEventListener('webkitfullscreenchange', handleFullscreenChange)
      document.removeEventListener('mozfullscreenchange', handleFullscreenChange)
      document.removeEventListener('MSFullscreenChange', handleFullscreenChange)
    }
  }, [selectedImage])


  // Enhanced swipe gesture handlers for iPhone
  const handleTouchStart = (e) => {
    // Handle pinch gestures
    if (e.touches.length === 2) {
      const touch1 = e.touches[0];
      const touch2 = e.touches[1];
      const distance = Math.sqrt(
        Math.pow(touch2.clientX - touch1.clientX, 2) +
        Math.pow(touch2.clientY - touch1.clientY, 2)
      );
      setPinchStart({ distance, touches: [touch1, touch2] });
      return;
    }

    // Handle single touch for swipe gestures
    setTouchEnd(null)
    setTouchStart(e.targetTouches[0].clientX)
    setTouchStartPos({ x: e.targetTouches[0].clientX, y: e.targetTouches[0].clientY })
    setTouchCurrentPos({ x: e.targetTouches[0].clientX, y: e.targetTouches[0].clientY })
    console.log('📱 Touch start:', e.targetTouches[0].clientX)
  }

  const handleTouchMove = (e) => {
    // Handle pinch gestures
    if (e.touches.length === 2 && pinchStart) {
      const touch1 = e.touches[0];
      const touch2 = e.touches[1];
      const distance = Math.sqrt(
        Math.pow(touch2.clientX - touch1.clientX, 2) +
        Math.pow(touch2.clientY - touch1.clientY, 2)
      );
      
      const scaleChange = distance / pinchStart.distance;
      
      // If pinch gesture is significant, toggle zoom
      if (scaleChange > 1.2) {
        setIsZoomed(true);
      } else if (scaleChange < 0.8) {
        setIsZoomed(false);
      }
      return;
    }

    // Handle single touch for swipe gestures
    setTouchEnd(e.targetTouches[0].clientX)
    setTouchCurrentPos({ x: e.targetTouches[0].clientX, y: e.targetTouches[0].clientY })
    // Prevent the page from scrolling while swiping horizontally
    if (e.cancelable) {
      e.preventDefault()
    }
  }

  const handleTouchEnd = () => {
    // Reset pinch state
    setPinchStart(null);

    // Handle swipe gestures
    if (!touchStartPos || !touchCurrentPos) return
    
    const deltaX = touchStartPos.x - touchCurrentPos.x
    const deltaY = touchStartPos.y - touchCurrentPos.y
    const absX = Math.abs(deltaX)
    const absY = Math.abs(deltaY)
    
    // Require dominant horizontal movement to avoid accidental triggers while scrolling
    const horizontalDominant = absX > absY * 1.5
    const threshold = 30
    const isLeftSwipe = horizontalDominant && deltaX > threshold
    const isRightSwipe = horizontalDominant && deltaX < -threshold

    console.log('📱 Touch end - deltaX/deltaY:', deltaX, deltaY, 'left:', isLeftSwipe, 'right:', isRightSwipe)

    if (isLeftSwipe) {
      console.log('👈 Swipe left - next image')
      showNextImage()
    }
    if (isRightSwipe) {
      console.log('👉 Swipe right - previous image')
      showPreviousImage()
    }
    
    // Reset touch states
    setTouchStart(null)
    setTouchEnd(null)
    setTouchStartPos(null)
    setTouchCurrentPos(null)
  }

  const fetchImages = async () => {
    try {
      setLoading(true)
      setError(null)
      
      if (!category?.folder) {
        throw new Error('Category folder is required')
      }

      // Create URL with properly encoded path parameter
      const url = new URL('/api/images', window.location.origin);
      url.searchParams.set('path', category.folder);

      console.log('Fetching images for category:', category.folder);
      console.log('Request URL:', url.toString());
      
      const response = await fetch(url.toString())
      console.log('API Response status:', response.status)
      
      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.error || `HTTP error! status: ${response.status}`)
      }
      
      const data = await response.json()
      console.log('Received images:', data)
      
      if (!data.images || !Array.isArray(data.images)) {
        throw new Error('Invalid image data received')
      }
      
      setImages(data.images)
      
      // Load existing comments from localStorage
      loadCommentsFromStorage(data.images)
      
      // Load and apply custom image order if it exists
      applyCustomImageOrder(data.images)
    } catch (error) {
      console.error('Error fetching images:', error)
      setError(error.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchImages()
  }, [category?.folder, refreshKey])

  const handleRefresh = () => {
    setRefreshKey(prev => prev + 1)
  }

  useEffect(() => {
    // Cleanup slideshow interval on unmount
    return () => {
      if (slideshowInterval) {
        clearInterval(slideshowInterval)
      }
    }
  }, [slideshowInterval])

  // Listen for fullscreen changes
  useEffect(() => {
    const handleFullscreenChange = () => {
      setIsFullscreen(!!document.fullscreenElement);
    };

    document.addEventListener('fullscreenchange', handleFullscreenChange);
    
    return () => {
      document.removeEventListener('fullscreenchange', handleFullscreenChange);
    };
  }, []);

  // Listen for scroll events to show/hide back to top button
  useEffect(() => {
    const handleScroll = () => {
      const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
      const shouldShow = scrollTop > 100;
      setShowBackToTop(shouldShow);
    };

    window.addEventListener('scroll', handleScroll);
    
    return () => {
      window.removeEventListener('scroll', handleScroll);
    };
  }, []);

  const handleImageClick = async (image) => {
    setSelectedImage(image)
    stopSlideshow()
    const imagePath = image.src.split('/images/portfolio/')[1]
    const imageComments = await fetchComments(imagePath)
    setComments(imageComments)
  }

  const closeFullscreen = () => {
    setSelectedImage(null)
    stopSlideshow()
    setIsFullscreen(false)
  }

  const scrollToTop = () => {
    window.scrollTo({
      top: 0,
      behavior: 'smooth'
    });
  };

  const startSlideshow = () => {
    setIsSlideshow(true)
    const interval = setInterval(() => {
      setSelectedImage((current) => {
        const currentIndex = images.findIndex(img => img.src === current.src)
        const nextIndex = (currentIndex + 1) % images.length
        return images[nextIndex]
      })
    }, 3000) // Change image every 3 seconds
    setSlideshowInterval(interval)
  }

  const stopSlideshow = () => {
    if (slideshowInterval) {
      clearInterval(slideshowInterval)
      setSlideshowInterval(null)
    }
    setIsSlideshow(false)
  }

  const showNextImage = () => {
    if (!selectedImage || !images || images.length === 0) return;
    
    const currentIndex = images.findIndex(img => img.src === selectedImage.src)
    if (currentIndex === -1) return;
    
    // If current image has a title and title is being shown, hide title for next image
    const currentImageTitle = loadTitleFromStorage(selectedImage.src)
    if (currentImageTitle && showTitle) {
      setShowTitle(false)
    }
    
    const nextIndex = (currentIndex + 1) % images.length
    console.log('Navigating to next image:', { currentIndex, nextIndex, totalImages: images.length })
    setSelectedImage(images[nextIndex])
  }

  const showPreviousImage = () => {
    if (!selectedImage || !images || images.length === 0) return;
    
    const currentIndex = images.findIndex(img => img.src === selectedImage.src)
    if (currentIndex === -1) return;
    
    // If current image has a title and title is being shown, hide title for previous image
    const currentImageTitle = loadTitleFromStorage(selectedImage.src)
    if (currentImageTitle && showTitle) {
      setShowTitle(false)
    }
    
    const previousIndex = (currentIndex - 1 + images.length) % images.length
    console.log('Navigating to previous image:', { currentIndex, previousIndex, totalImages: images.length })
    setSelectedImage(images[previousIndex])
  }

  const saveComment = async () => {
    try {
      const imagePath = selectedImage.src.split('/images/portfolio/')[1];
      console.log('Saving comment for image:', imagePath);
      
      const response = await fetch('/api/comments', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({ 
          imagePath,
          comment: editingComment 
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error('Server response:', errorText);
        throw new Error(errorText || 'Failed to save comment');
      }

      try {
        const responseData = await response.json();
        console.log('Response data:', responseData);

        // Update the image in the local state
        setImages(images.map(img => 
          img.src === selectedImage.src 
            ? { ...img, comment: editingComment }
            : img
        ));
        setSelectedImage({ ...selectedImage, comment: editingComment });
        setIsEditingComment(false);
      } catch (jsonError) {
        throw new Error('Invalid JSON response from server');
      }
    } catch (error) {
      console.error('Error saving comment:', error);
      console.error('Full error details:', {
        message: error.message,
        stack: error.stack,
      });
      alert(`Failed to save comment: ${error.message}`);
    }
  };

  // Function to fetch comments
  const fetchComments = async (imagePath) => {
    try {
      const response = await fetch(`/api/comments?path=${encodeURIComponent(imagePath)}`);
      if (!response.ok) {
        throw new Error('Failed to fetch comments');
      }
      const data = await response.json();
      return data.comments;
    } catch (error) {
      console.error('Error fetching comments:', error);
      return [];
    }
  };

  // Function to add a new comment
  const handleAddComment = async (commentText) => {
    try {
      // For now, add comments locally since the API endpoint doesn't exist yet
      const imagePath = selectedImage.src.split('/images/portfolio/')[1]
      if (!imagePath) {
        throw new Error('Could not determine image path')
      }
      
      const newComment = {
        id: Date.now(),
        text: commentText,
        author: 'User',
        timestamp: new Date().toISOString(),
        likes: 0,
        replies: [],
        imagePath: imagePath
      };
      
      const updatedComments = [...comments, newComment];
      setComments(updatedComments);
      
      // Save to localStorage
      saveCommentsToStorage(imagePath, updatedComments.filter(c => c.imagePath === imagePath));
      
      setIsEditingComment(false);
      alert('Comment added successfully!');
    } catch (error) {
      console.error('Error adding comment:', error);
      alert('Failed to add comment: ' + error.message);
    }
  };

  // Function to handle replies
  const handleReply = async (parentId, replyText) => {
    try {
      // For now, add replies locally since the API endpoint doesn't exist yet
      const newReply = {
        id: Date.now(),
        text: replyText,
        author: 'User',
        timestamp: new Date().toISOString(),
        likes: 0,
        parentId: parentId
      };
      
      setComments(prev => prev.map(comment => 
        comment.id === parentId 
          ? { ...comment, replies: [...comment.replies, newReply] }
          : comment
      ));
      
      setIsEditingComment(false);
      alert('Reply added successfully!');
    } catch (error) {
      console.error('Error adding reply:', error);
      alert('Failed to add reply: ' + error.message);
    }
  };

  // Function to handle likes
  const handleLike = async (commentId) => {
    try {
      // For now, handle likes locally since the API endpoint doesn't exist yet
      setComments(prev => prev.map(comment => 
        comment.id === commentId 
          ? { ...comment, likes: comment.likes + 1 }
          : comment
      ));
      
      alert('Comment liked!');
    } catch (error) {
      console.error('Error liking comment:', error);
      alert('Failed to like comment: ' + error.message);
    }
  };

  // Function to handle editing comments
  const handleEditComment = async (commentId, newText) => {
    try {
      // For now, edit comments locally since the API endpoint doesn't exist yet
      setComments(prev => prev.map(comment => 
        comment.id === commentId 
          ? { ...comment, text: newText }
          : comment
      ));
      
      alert('Comment edited successfully!');
    } catch (error) {
      console.error('Error editing comment:', error);
      alert('Failed to edit comment: ' + error.message);
    }
  };

  // Function to handle deleting comments
  const handleDeleteComment = async (commentId) => {
    try {
      // For now, delete comments locally since the API endpoint doesn't exist yet
      setComments(prev => prev.filter(comment => comment.id !== commentId));
      alert('Comment deleted successfully!');
    } catch (error) {
      console.error('Error deleting comment:', error);
      alert('Failed to delete comment: ' + error.message);
    }
  };

  // Function to handle title updates
  const handleTitleUpdate = async (newTitle) => {
    try {
      // Save title to localStorage (empty string will delete the title)
      if (newTitle.trim()) {
        saveTitleToStorage(selectedImage.src, newTitle);
        alert('Title updated successfully!');
      } else {
        // Delete the title completely
        deleteTitleFromStorage(selectedImage.src);
        alert('Title deleted successfully!');
      }
      
      setTitleText('');
      setEditingTitle(false);
    } catch (error) {
      console.error('Error updating title:', error);
      alert('Failed to update title');
    }
  };

  // Function to save title to localStorage
  const saveTitleToStorage = (imageSrc, title) => {
    try {
      const imagePath = imageSrc.split('/images/portfolio/')[1]
      if (imagePath) {
        const storageKey = `title_${imagePath}`
        localStorage.setItem(storageKey, title)
      }
    } catch (error) {
      console.error('Error saving title to localStorage:', error)
    }
  }

  // Function to load title from localStorage
  const loadTitleFromStorage = (imageSrc) => {
    try {
      const imagePath = imageSrc.split('/images/portfolio/')[1]
      if (imagePath) {
        const storageKey = `title_${imagePath}`
        const storedTitle = localStorage.getItem(storageKey)
        return storedTitle || null
      }
    } catch (error) {
      console.error('Error loading title from localStorage:', error)
    }
    return null
  }

  // Function to delete title from localStorage
  const deleteTitleFromStorage = (imageSrc) => {
    try {
      const imagePath = imageSrc.split('/images/portfolio/')[1]
      if (imagePath) {
        const storageKey = `title_${imagePath}`
        localStorage.removeItem(storageKey)
      }
    } catch (error) {
      console.error('Error deleting title from localStorage:', error)
    }
  }

  // Function to delete an image
  const handleDeleteImage = async (imageToDelete) => {
    try {
      console.log('🗑️ Deleting image:', imageToDelete.src)
      
      // Extract the relative path from the image src
      const imagePath = imageToDelete.src.replace('/images/portfolio/', '')
      
      // Call the delete API
      const response = await fetch('/api/delete-image', {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          imagePath: imagePath,
          category: category.folder
        })
      })

      if (!response.ok) {
        throw new Error(`Failed to delete image: ${response.statusText}`)
      }

      const result = await response.json()
      console.log('✅ Image deleted successfully:', result)

      // Remove the image from the local state
      setImages(prevImages => prevImages.filter(img => img.id !== imageToDelete.id))
      
      // Close fullscreen if the deleted image was selected
      if (selectedImage && selectedImage.id === imageToDelete.id) {
        closeFullscreen()
      }

      // Show success message
      alert('Image deleted successfully!')
      
      // Refresh the gallery to ensure consistency
      handleRefresh()
      
    } catch (error) {
      console.error('❌ Error deleting image:', error)
      alert(`Failed to delete image: ${error.message}`)
    }
  }

  // Function to save comments to localStorage
  const saveCommentsToStorage = (imagePath, commentList) => {
    try {
      const storageKey = `comments_${imagePath}`
      localStorage.setItem(storageKey, JSON.stringify(commentList))
    } catch (error) {
      console.error('Error saving comments to localStorage:', error)
    }
  }

  // Function to load comments from localStorage
  const loadCommentsFromStorage = (imageList) => {
    try {
      const allComments = []
      imageList.forEach(image => {
        const imagePath = image.src.split('/images/portfolio/')[1]
        if (imagePath) {
          const storageKey = `comments_${imagePath}`
          const storedComments = localStorage.getItem(storageKey)
          if (storedComments) {
            const parsedComments = JSON.parse(storedComments)
            allComments.push(...parsedComments)
          }
        }
      })
      setComments(allComments)
    } catch (error) {
      console.error('Error loading comments from localStorage:', error)
    }
  }

  // Function to apply custom image order from localStorage
  const applyCustomImageOrder = (imageList) => {
    try {
      const storageKey = `imageOrder_${category.folder}`
      const storedOrder = localStorage.getItem(storageKey)
      
      if (storedOrder) {
        const orderData = JSON.parse(storedOrder)
        
        // Check if the stored order is for the current category
        if (orderData.category === category.folder && orderData.order) {
          // Create a map of image IDs to images for quick lookup
          const imageMap = new Map(imageList.map(img => [img.id, img]))
          
          // Reorder images according to the stored order
          const reorderedImages = []
          orderData.order.forEach(imageId => {
            const image = imageMap.get(imageId)
            if (image) {
              reorderedImages.push(image)
              imageMap.delete(imageId) // Remove from map to avoid duplicates
            }
          })
          
          // Add any remaining images that weren't in the order (new images)
          imageMap.forEach(image => {
            reorderedImages.push(image)
          })
          
          setImages(reorderedImages)
          return
        }
      }
      
      // If no custom order, use the original order
      setImages(imageList)
    } catch (error) {
      console.error('Error applying custom image order:', error)
      setImages(imageList) // Fallback to original order
    }
  }

  // Modify the keyboard event handler
  useEffect(() => {
    const handleKeyPress = (e) => {
      if (!selectedImage) return;
      
      // Don't handle space key if we're editing a comment
      if (e.key === ' ' && isEditingComment) {
        return;
      }
      
      switch(e.key) {
        case 'Escape':
          if (isEditingComment) {
            setIsEditingComment(false);
          } else {
            closeFullscreen();
          }
          break;
        case 'ArrowLeft':
          e.preventDefault();
          showPreviousImage();
          break;
        case 'ArrowRight':
          e.preventDefault();
          showNextImage();
          break;
        case ' ':
          e.preventDefault();
          if (!isEditingComment) {
            isSlideshow ? stopSlideshow() : startSlideshow();
          }
          break;
        case 'f':
          setIsZoomed(!isZoomed);
          break;
        case 'c':
          if (!isEditingComment) {
            setEditingComment(selectedImage.comment || '');
            setIsEditingComment(true);
          }
          break;
        default:
          break;
      }
    };

    window.addEventListener('keydown', handleKeyPress);
    return () => window.removeEventListener('keydown', handleKeyPress);
  }, [selectedImage, isSlideshow, isZoomed, isEditingComment]);

  return (
    <GalleryContainer>
      <BackButton onClick={() => {
        if (parentCategory) {
          onSubcategoryClick(parentCategory);
        } else {
          onBack();
        }
      }}>
        ← Back to {parentCategory ? parentCategory.title : "Categories"}
      </BackButton>
      
      <GalleryHeader>
        <GalleryTitle>{category.title}</GalleryTitle>
        <RefreshButton onClick={handleRefresh}>
          ↻ Refresh Gallery
        </RefreshButton>
      </GalleryHeader>

      {subcategories.length > 0 && (
        <SubcategoryGrid>
          {subcategories.map((subcat) => (
            <SubcategoryCard 
              key={subcat.id}
              onClick={() => onSubcategoryClick(subcat)}
            >
              <SubcategoryTitle>{subcat.title}</SubcategoryTitle>
            </SubcategoryCard>
          ))}
        </SubcategoryGrid>
      )}

      {loading && (
        <div style={{ textAlign: 'center', padding: '2rem' }}>
          Loading images...
        </div>
      )}

      {error && (
        <div style={{ 
          textAlign: 'center', 
          padding: '2rem', 
          color: 'red',
          backgroundColor: '#fff1f1',
          borderRadius: '8px',
          margin: '1rem 0'
        }}>
          Error loading images: {error}
        </div>
      )}

      <ImageGrid>
        {images.map((image, index) => (
          <GalleryImage 
            key={image.id + image.lastModified}
            image={image}
            onClick={handleImageClick}
            index={index}
          />
        ))}
      </ImageGrid>

      {selectedImage && (
        <FullscreenOverlay 
          onClick={(e) => {
            // Only close if clicking directly on the overlay background
            if (e.target === e.currentTarget) {
              closeFullscreen();
            }
          }}
          onTouchStart={handleTouchStart}
          onTouchMove={handleTouchMove}
          onTouchEnd={handleTouchEnd}
          style={{
            // Ensure touch events work properly on iOS
            WebkitTouchCallout: 'none',
            WebkitUserSelect: 'none',
            touchAction: 'none'
          }}
        >


          {/* Show controls only when NOT in fullscreen mode */}
          {!isFullscreen && (
            <>
              <ImageCounter>
                {images.findIndex(img => img.src === selectedImage.src) + 1} / {images.length}
              </ImageCounter>
              
              <CloseButton onClick={closeFullscreen} title="Close (Esc)">×</CloseButton>
              

            </>
          )}
          
          <FullscreenImage 
            src={getOptimalImageSrc(selectedImage.src, true)} 
            alt={selectedImage.alt}
            onError={(e) => {
              console.error('Failed to load fullscreen image, trying fallbacks:', selectedImage.src)
              const img = e.target;
              const currentSrc = img.src;
              
              // Try fallback order: large -> previews -> original
              if (currentSrc.includes('/optimized/full/')) {
                // Try large if full fails
                img.src = currentSrc.replace('/optimized/full/', '/optimized/large/');
              } else if (currentSrc.includes('/optimized/large/')) {
                // Try previews if large fails
                img.src = currentSrc.replace('/optimized/large/', '/optimized/previews/');
              } else if (currentSrc.includes('/optimized/previews/')) {
                // Fallback to original if all optimized versions fail
                img.src = selectedImage.src;
              }
              // If still fails, user will see broken image but at least we tried
            }}
            onClick={(e) => {
              e.stopPropagation();
              setIsZoomed(!isZoomed);
            }}
            css={isZoomed ? { 
              transform: 'scale(1.5)', 
              cursor: 'zoom-out'
            } : { 
              cursor: 'zoom-in'
            }}
          />
          
          {/* Swipe indicator for mobile */}
          <SwipeIndicator>
            👈 Swipe to navigate 👉
          </SwipeIndicator>
          
          {/* Bottom Controls - Hidden in Fullscreen */}
          {!isFullscreen && (
            <FullscreenControls onClick={(e) => e.stopPropagation()}>
              <ControlButton onClick={showPreviousImage} title="Previous (←)">
                <span className="desktop-text">← Previous</span>
                <span className="mobile-text">←</span>
              </ControlButton>
              {isSlideshow ? (
                <ControlButton onClick={stopSlideshow} title="Stop Slideshow (Space)">
                  <span className="desktop-text">⏸ Stop Slideshow</span>
                  <span className="mobile-text">⏸</span>
                </ControlButton>
              ) : (
                <ControlButton onClick={startSlideshow} title="Start Slideshow (Space)">
                  <span className="desktop-text">▶ Start Slideshow</span>
                  <span className="mobile-text">▶</span>
                </ControlButton>
              )}
              <ControlButton onClick={showNextImage} title="Next (→)">
                <span className="desktop-text">Next →</span>
                <span className="mobile-text">→</span>
              </ControlButton>
              <ControlButton 
                onClick={() => {
                  setEditingComment(selectedImage.comment || '');
                  setIsEditingComment(true);
                }}
                title="Edit Comment (C)"
              >
                <span className="desktop-text">✎ Edit Comment</span>
                <span className="mobile-text">✎</span>
              </ControlButton>
              {/* Title editing - Admin only */}
              {isAdmin && (
                <ControlButton 
                  onClick={() => {
                    if (!editingTitle) {
                      setEditingTitle(true);
                      setTitleText(loadTitleFromStorage(selectedImage.src) || '');
                    } else {
                      // Save the title (allow empty to delete)
                      handleTitleUpdate(titleText.trim());
                    }
                  }}
                  title="Edit Title (T)"
                >
                  <span className="desktop-text">{editingTitle ? '💾 Save Title' : '✏️ Edit Title'}</span>
                  <span className="mobile-text">{editingTitle ? '💾' : '✏️'}</span>
                </ControlButton>
              )}

              <ControlButton 
                onClick={() => {
                  setShowTitle(prev => !prev);
                }}
                title="Toggle Title Display (D)"
              >
                <span className="desktop-text">{showTitle ? '🔽 Hide Title' : '🔼 Show Title'}</span>
                <span className="mobile-text">{showTitle ? '🔽' : '🔼'}</span>
              </ControlButton>
              <ControlButton 
                onClick={(e) => {
                  e.stopPropagation();
                  const filename = selectedImage.src.split('/').pop();
                  downloadImage(selectedImage.src, filename);
                }}
                title="Download Full Resolution Image"
              >
                <span className="desktop-text">⬇ Download</span>
                <span className="mobile-text">⬇</span>
              </ControlButton>
              <ControlButton 
                onClick={() => {
                  if (isFullscreen) {
                    document.exitFullscreen();
                  } else {
                    document.documentElement.requestFullscreen();
                  }
                }}
                title="Toggle Fullscreen (F)"
              >
                <span className="desktop-text">{isFullscreen ? '⏹ Exit Fullscreen' : '⛶ Fullscreen'}</span>
                <span className="mobile-text">{isFullscreen ? '⏹' : '⛶'}</span>
              </ControlButton>
            </FullscreenControls>
          )}

          {/* Fullscreen Navigation Arrows - Hidden in true fullscreen */}
          {isFullscreen && (
            <>
            </>
          )}
          
          {/* Title Editing Input */}
          {editingTitle && (
            <TitleEditOverlay 
              onClick={(e) => {
                // Click outside input to exit editing
                if (e.target === e.currentTarget) {
                  setEditingTitle(false);
                  setTitleText('');
                }
              }}
            >
              <TitleEditInput
                value={titleText}
                onChange={(e) => setTitleText(e.target.value)}
                onKeyPress={(e) => {
                  if (e.key === 'Enter') {
                    handleTitleUpdate(titleText.trim());
                  } else if (e.key === 'Escape') {
                    setEditingTitle(false);
                    setTitleText('');
                  }
                }}
                placeholder="Enter image title (leave empty to delete)"
                autoFocus
              />
            </TitleEditOverlay>
          )}

          {/* Image Title - Toggleable (only show if title exists) */}
          {showTitle && loadTitleFromStorage(selectedImage.src) && (
            <ImageTitle>
              {loadTitleFromStorage(selectedImage.src)}
            </ImageTitle>
          )}

          {isEditingComment && (
            <CommentEditArea onClick={(e) => e.stopPropagation()}>
              <CommentThread
                comments={comments}
                onAddComment={handleAddComment}
                onReply={handleReply}
                onLike={handleLike}
                onEdit={handleEditComment}
                onDelete={handleDeleteComment}
              />
            </CommentEditArea>
          )}
        </FullscreenOverlay>
      )}

      {/* Back to Top Button */}
      <BackToTopButton 
        className={showBackToTop ? 'visible' : ''}
        onClick={scrollToTop}
        title="Back to Top"
        aria-label="Back to top of gallery"
      >
        ↑
      </BackToTopButton>
    </GalleryContainer>
  )
}

export default CategoryGallery 