import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/home_header.dart';
import '../widgets/destination_hero_card.dart';
import '../widgets/destination_skeleton.dart';
import '../widgets/ai_input_bar.dart';
import '../widgets/mist_navigation.dart';
import '../../../../core/widgets/emergency_button.dart'; 

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLoading = false;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              const HomeHeader(),

              if (isLoading)
                const DestinationSkeleton()
              else
                DestinationHeroCard(
                  title: "Salto de la China",
                  category: "Naturaleza • A 45 min",
                  description: "Un velo de agua de 70 m, escondido en lo profundo de los bosques de araucarias.",
                  imageUrl: 'https://images.unsplash.com/photo-1596230529625-7ee10f7b09b6?q=80&w=1000',
                  onSetRoute: () => context.push('/map'),
                  onDetails: () => context.push('/itinerary-detail'),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 150)), 
            ],
          ),

          const Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              top: true,
              left: true,
              right: false,
              bottom: false,
              child: EmergencyButton(),
            ),
          ),
          

          const Positioned(
            bottom: 0, left: 0, right: 0, 
            child: MistNavigation()
          ),

          const Positioned(
            bottom: 90, left: 20, right: 20, 
            child: AIInputBar()
          ),
        ],
      ),
    );
  }
}