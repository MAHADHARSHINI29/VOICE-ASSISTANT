import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  const ChatMessage({
    super.key,
    required this.text,
    required this.sender,
    this.isImage = false,
  });

  final String text;
  final String sender;
  final bool isImage;

  @override
  Widget build(BuildContext context) {
    final isUser = sender == "user";
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isUser ? theme.primaryColor : theme.cardColor,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: isImage
            ? AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  text,
                  loadingBuilder: (context, child, loadingProgress) =>
                      loadingProgress == null
                          ? child
                          : const CircularProgressIndicator.adaptive(),
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : theme.textTheme.bodyMedium?.color,
                  fontSize: 16.0,
                ),
              ),
      ),
    );
  }
}
