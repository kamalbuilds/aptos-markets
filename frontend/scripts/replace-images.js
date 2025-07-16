#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

/**
 * Image Replacement Script for Aptos Markets Rebranding
 * 
 * This script helps replace old image references with new ones
 * Run: node scripts/replace-images.js
 */

// Image mapping: old filename -> new filename
const IMAGE_MAPPINGS = {
    // Character/Logo images
    'mr_peeltos.png': 'aptos_markets_logo.png',
    'profile_pic.jpg': 'aptos_markets_avatar.jpg',
    'peeltos_approved.png': 'aptos_markets_approved.png',
    'peeltos-hawai.jpg': 'aptos_markets_celebration.jpg',
    'Character_MAGA2.jpg': 'aptos_markets_character.jpg',

    // Product previews
    'pp-preview-purple.jpg': 'aptos_markets_preview.jpg',

    // AI/Brain concepts
    'banana_brain.png': 'ai_brain.png',
    'brain.png': 'ai_analytics.png',

    // Backgrounds
    'bananas-light.jpg': 'aptos_markets_bg_light.jpg',
    'bg-dark.jpg': 'aptos_markets_bg_dark.jpg',
    'bg-dark-mobile.jpg': 'aptos_markets_bg_dark_mobile.jpg',
    'bg-light.jpg': 'aptos_markets_bg_light.jpg',

    // Technical/News
    'tech_stack_news.png': 'aptos_tech_stack.png',
    'news_countdown.png': 'aptos_countdown.png',
    'pp-architecture.png': 'aptos_markets_architecture.png',

    // Icons
    'favicon.png': 'aptos_markets_favicon.png'
};

// Files that need to be updated with new image references
const FILES_TO_UPDATE = [
    'README.md',
    'lib/send-telegram-news-notification.ts',
    'app/global-error.tsx',
    'components/header.tsx',
    'components/providers/wallet-provider.tsx',
    'app/layout.tsx',
    'app/(dashboard)/DashboardLayout.tsx',
    'app/api/telegram/webhook/route.ts',
    'app/(dashboard)/layout.tsx',
    'app/(dashboard)/profile/page.tsx'
];

function checkImageExists(imagePath) {
    return fs.existsSync(path.join('public', imagePath));
}

function updateFileReferences(filePath, oldImage, newImage) {
    try {
        const fullPath = path.resolve(filePath);
        if (!fs.existsSync(fullPath)) {
            console.log(`⚠️  File not found: ${filePath}`);
            return false;
        }
        let content = fs.readFileSync(fullPath, 'utf8');
        let updated = false;

        // Replace various formats of image references
        const patterns = [
            new RegExp(`/${oldImage}`, 'g'),
            new RegExp(`"/${oldImage}"`, 'g'),
            new RegExp(`'/${oldImage}'`, 'g'),
            new RegExp(`\\(/${oldImage}\\)`, 'g'),
            new RegExp(`url\\('/${oldImage}'\\)`, 'g'),
            new RegExp(`url\\("/${oldImage}"\\)`, 'g'),
            new RegExp(`https://app\\.aptos-markets-predictions\\.xyz/${oldImage}`, 'g'),
            new RegExp(`\\./public/${oldImage}`, 'g')
        ];

        patterns.forEach(pattern => {
            if (pattern.test(content)) {
                content = content.replace(pattern, (match) => {
                    updated = true;
                    return match.replace(oldImage, newImage);
                });
            }
        });

        if (updated) {
            fs.writeFileSync(fullPath, content, 'utf8');
            console.log(`✅ Updated ${filePath}: ${oldImage} -> ${newImage}`);
            return true;
        }

        return false;
    } catch (error) {
        console.error(`❌ Error updating ${filePath}:`, error.message);
        return false;
    }
}

function main() {
    console.log('🏛️ Aptos Markets - Image Replacement Script\n');

    // Check which new images exist
    console.log('📋 Checking for new images...\n');
    const missingImages = [];
    const availableImages = [];

    Object.entries(IMAGE_MAPPINGS).forEach(([oldImage, newImage]) => {
        if (checkImageExists(newImage)) {
            availableImages.push({ oldImage, newImage });
            console.log(`✅ Found: ${newImage}`);
        } else {
            missingImages.push({ oldImage, newImage });
            console.log(`❌ Missing: ${newImage}`);
        }
    });

    if (missingImages.length > 0) {
        console.log(`\n⚠️  ${missingImages.length} images are missing. Please add them to /public folder:`);
        missingImages.forEach(({ newImage }) => {
            console.log(`   - ${newImage}`);
        });
        console.log('\nRun this script again after adding the missing images.\n');
    }

    if (availableImages.length === 0) {
        console.log('❌ No new images found. Please add images to /public folder first.');
        return;
    }

    // Update code references for available images
    console.log(`\n🔄 Updating code references for ${availableImages.length} available images...\n`);

    let totalUpdates = 0;
    availableImages.forEach(({ oldImage, newImage }) => {
        console.log(`\n📝 Updating references: ${oldImage} -> ${newImage}`);

        FILES_TO_UPDATE.forEach(filePath => {
            if (updateFileReferences(filePath, oldImage, newImage)) {
                totalUpdates++;
            }
        });
    });

    console.log(`\n🎉 Completed! Updated ${totalUpdates} file references.`);

    if (missingImages.length > 0) {
        console.log(`\n⏳ Still waiting for ${missingImages.length} images to be added.`);
    } else {
        console.log('\n✅ All images have been successfully replaced!');
    }
}

// Run the script
if (require.main === module) {
    main();
}

module.exports = { IMAGE_MAPPINGS, updateFileReferences }; 