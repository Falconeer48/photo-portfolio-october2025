# Photo Portfolio Commands - Quick Reference

All these commands can be run from anywhere on your system.

## 🚀 Main Commands

### `photo-portfolio-deploy-anywhere.sh`
**Run from anywhere to deploy your photo portfolio**
```bash
photo-portfolio-deploy-anywhere.sh
```
- Automatically navigates to project directory
- Runs full system integrity tests
- Offers deployment options
- **Use this for most deployments**

### `photo-portfolio-test-anywhere.sh`
**Run from anywhere to test your system**
```bash
photo-portfolio-test-anywhere.sh
```
- Tests everything without deploying
- Good for troubleshooting
- Verifies all components are working

## 📁 Project Directory Commands

These commands must be run from within the photo portfolio project directory:

### `photo-portfolio-deploy.sh`
**Main deployment pipeline (from project directory)**
```bash
cd "/Volumes/M2 Drive/M2 Downloads/Cursor Projects/photo-portfolio"
./deploy.sh
```

### `photo-portfolio-quick-deploy.sh`
**Fast deployment for minor changes**
```bash
cd "/Volumes/M2 Drive/M2 Downloads/Cursor Projects/photo-portfolio"
./scripts/quick-deploy.sh
```

### `photo-portfolio-test.sh`
**System integrity test (from project directory)**
```bash
cd "/Volumes/M2 Drive/M2 Downloads/Cursor Projects/photo-portfolio"
./scripts/test-system.sh
```

## 🎯 Quick Start

For most deployments, simply run:
```bash
photo-portfolio-deploy-anywhere.sh
```

This will:
1. ✅ Test your entire system
2. ✅ Deploy if tests pass
3. ✅ Verify deployment worked
4. ✅ Tell you if anything is wrong

## 🔧 Troubleshooting

If something goes wrong:
1. Run `photo-portfolio-test-anywhere.sh` to diagnose issues
2. Check the error messages for specific problems
3. Fix issues locally
4. Re-run deployment

## 📍 Project Location

Your photo portfolio project is located at:
```
/Volumes/M2 Drive/M2 Downloads/Cursor Projects/photo-portfolio
```

## 🌐 Live Site

Your photo portfolio is live at:
```
http://192.168.50.243:3000
``` 