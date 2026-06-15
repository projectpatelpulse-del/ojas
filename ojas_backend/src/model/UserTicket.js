const mongoose = require('mongoose');

const userTicketSchema = new mongoose.Schema({
  ticketId: {
    type: String,
    required: true,
    unique: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  userName: String,
  email: String,
  phone: String,
  category: {
    type: String,
    enum: ['General', 'Order Support', 'Payment Issue', 'Product Quality', 'Technical Help', 'Other'],
    default: 'General'
  },
  subject: {
    type: String,
    required: true
  },
  message: {
    type: String,
    required: true
  },
  status: {
    type: String,
    enum: ['Open', 'In Progress', 'Resolved', 'Closed'],
    default: 'Open'
  },
  priority: {
    type: String,
    enum: ['Low', 'Medium', 'High', 'Urgent'],
    default: 'Medium'
  },
  responses: [{
    sender: {
      type: String,
      enum: ['Admin', 'User']
    },
    message: String,
    createdAt: {
      type: Date,
      default: Date.now
    }
  }]
}, { timestamps: true });

module.exports = mongoose.model('UserTicket', userTicketSchema);
