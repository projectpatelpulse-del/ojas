const mongoose = require('mongoose');

const resourceSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true,
        trim: true
    },
    description: {
        type: String,
        default: '',
        trim: true
    },
    type: {
        type: String,
        enum: ['VIDEO', 'PDF', 'BLOG'],
        required: true
    },
    url: {
        type: String,
        required: function() { return this.type !== 'BLOG'; },
        trim: true
    },
    content: {
        type: String,
        default: '',
        trim: true
    },
    // For VIDEO: YouTube video ID or full URL
    thumbnailUrl: {
        type: String,
        default: ''
    },
    category: {
        type: String,
        default: 'General',
        trim: true
    },
    targetAudience: {
        type: String,
        enum: ['VENDOR', 'USER', 'ALL'],
        default: 'VENDOR'
    },
    order: {
        type: Number,
        default: 0
    },
    isActive: {
        type: Boolean,
        default: true
    }
}, { timestamps: true });

module.exports = mongoose.model('Resource', resourceSchema);
