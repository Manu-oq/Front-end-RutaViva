import 'package:flutter/material.dart';
import '../widgets/itinerary_step_widget.dart';
import '../widgets/cultural_insight_card.dart';
import '../widgets/trail_intelligence_box.dart';

class ItineraryDetailPage extends StatelessWidget {
  const ItineraryDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text("DÍA 1", style: theme.textTheme.labelLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("El Camino Narrativo", style: theme.textTheme.displayLarge),
            const SizedBox(height: 12),
            Text(
              "Trazando las rutas tranquilas de la Araucanía. Un viaje a través de valles envueltos en niebla y la calidez de la hospitalidad rural.",
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 40),

            const ItineraryStepWidget(
              time: "08:30 — La Mañana de la Tejedora",
              description: "Comienza con la Sra. Rosa en Curarrehue. Su telar lleva la historia de tres generaciones de artesanos Mapuche.",
              child: CulturalInsightCard(
                label: "Sabiduría Cultural",
                text: "El hilo azul en nuestros textiles representa el espíritu del cielo. Nunca tejemos en silencio; tejemos las historias que hemos escuchado.",
              ),
            ),

            ItineraryStepWidget(
              time: "",
              description: "",
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network("https://images.unsplash.com/photo-1590736962236-407a505f9630", fit: BoxFit.cover),
              ),
            ),

            const SizedBox(height: 32),
            const TrailIntelligenceBox(),
            const SizedBox(height: 100), 
          ],
        ),
      ),
    );
  }
}