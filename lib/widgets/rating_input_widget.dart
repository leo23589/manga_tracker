import 'package:flutter/material.dart';

class RatingInputWidget extends StatelessWidget {
  final int currentRating;
  final ValueChanged<int> onRatingChanged;
  final int maxRating;
  final bool enabled;

  const RatingInputWidget({
    super.key,
    required this.currentRating,
    required this.onRatingChanged,
    this.maxRating = 10,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (int index) {
        final int starValue = index + 1;
        return InkWell(
          onTap: enabled ? () => onRatingChanged(starValue) : null,
          child: Icon(
            starValue <= currentRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 28,
          ),
        );
      }),
    );
  }
}
