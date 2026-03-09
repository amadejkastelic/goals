import 'dart:math';

class MotivationalQuotes {
  static final _random = Random();

  static const List<String> quotes = [
    "Small steps every day lead to big results.",
    "Your future self will thank you.",
    "Consistency is the key to success.",
    "Every day is a new opportunity to grow.",
    "Progress, not perfection.",
    "You're doing great. Keep going!",
    "One day at a time. One goal at a time.",
    "Believe in yourself and your journey.",
    "Stay focused, stay positive.",
    "The secret of getting ahead is getting started.",
    "Dream big, work hard, stay focused.",
    "Success is the sum of small efforts repeated daily.",
    "Don't watch the clock; do what it does. Keep going.",
    "Your only limit is your mind.",
    "Great things never come from comfort zones.",
    "Push yourself, because no one else is going to do it for you.",
    "Wake up with determination. Go to bed with satisfaction.",
    "The harder you work, the luckier you get.",
    "Success doesn't come from what you do occasionally. It comes from what you do consistently.",
    "Don't stop until you're proud.",
    "Every accomplishment starts with the decision to try.",
    "You are stronger than you think.",
    "Make today amazing.",
    "Keep your eyes on the stars and your feet on the ground.",
    "Do something today that your future self will thank you for.",
    "It's not about perfect. It's about effort.",
    "Stay patient and trust your journey.",
    "Be stronger than your excuses.",
    "Action is the foundational key to all success.",
    "The best time to start was yesterday. The next best time is now.",
  ];

  static String getRandomQuote() {
    return quotes[_random.nextInt(quotes.length)];
  }
}
