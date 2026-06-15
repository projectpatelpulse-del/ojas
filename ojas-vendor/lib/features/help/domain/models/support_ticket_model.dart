class SupportTicketModel {
  final String id;
  final String ticketId;
  final String category;
  final String subject;
  final String message;
  final String status;
  final String priority;
  final DateTime createdAt;
  final List<TicketResponse>? responses;

  SupportTicketModel({
    required this.id,
    required this.ticketId,
    required this.category,
    required this.subject,
    required this.message,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.responses,
  });

  factory SupportTicketModel.fromMap(Map<String, dynamic> map) {
    return SupportTicketModel(
      id: map['_id'] ?? '',
      ticketId: map['ticketId'] ?? '',
      category: map['category'] ?? 'General',
      subject: map['subject'] ?? '',
      message: map['message'] ?? '',
      status: map['status'] ?? 'Open',
      priority: map['priority'] ?? 'Medium',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      responses: map['responses'] != null 
          ? (map['responses'] as List).map((r) => TicketResponse.fromMap(r)).toList()
          : [],
    );
  }
}

class TicketResponse {
  final String sender;
  final String message;
  final DateTime createdAt;

  TicketResponse({
    required this.sender,
    required this.message,
    required this.createdAt,
  });

  factory TicketResponse.fromMap(Map<String, dynamic> map) {
    return TicketResponse(
      sender: map['sender'] ?? '',
      message: map['message'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}
