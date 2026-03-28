// movie_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie_model.dart';
import '../theme/app_theme.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;
  final double width;
  final double height;

  const MovieCard({
    super.key,
    required this.movie,
    required this.onTap,
    this.width = 120,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: movie.posterUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: movie.posterUrl,
                          width: width,
                          height: height,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: width,
                            height: height,
                            color: AppTheme.bgCard,
                            child: const Center(
                              child: Icon(Icons.movie,
                                  color: AppTheme.textMuted, size: 28),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: width,
                            height: height,
                            color: AppTheme.bgCard,
                            child: const Center(
                              child: Icon(Icons.broken_image,
                                  color: AppTheme.textMuted),
                            ),
                          ),
                        )
                      : Container(
                          width: width,
                          height: height,
                          color: AppTheme.bgCard,
                          child: const Center(
                            child: Icon(Icons.movie,
                                color: AppTheme.textMuted, size: 28),
                          ),
                        ),
                ),
                // Rating badge
                if (movie.voteAverage != null && movie.voteAverage! > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star,
                              size: 9, color: AppTheme.imdbColor),
                          const SizedBox(width: 2),
                          Text(
                            movie.ratingFormatted,
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // TV badge
                if (!movie.isMovie)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('TV',
                          style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                // Upcoming badge
                if (movie.isUpcoming)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('UPCOMING',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Title
            Text(
              movie.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
                height: 1.3,
              ),
            ),
            if (movie.year != null)
              Text(
                '${movie.year}',
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
