extends Node

# This is a singleton that drives everything. Nothing else refers to it, but it reaches into everything else.
func _ready() -> void:
    forever_game_loop()

func forever_game_loop():
    # Loop until the end of the universe
    while Global.table == null:
        # Shh....
        await get_tree().create_timer(0.1).timeout
    var table = Global.table
    
    while true:
        Global.statistics[Global.Statistic.ACTION_POINTS] = Global.max_statistic_values[Global.Statistic.ACTION_POINTS]
        await table.draw_cards()

        # Wait for the player to finish their turn
        # TODO: End turn button
        while table.state != Table.TableState.Idle || (Global.statistics[Global.Statistic.ACTION_POINTS] > 0 && table.hand.size() > 0):
            await table.state_changed
        
        # End the player's turn
        await table.end_turn()

        # Process the fire
        if Global.statistics[Global.Statistic.FIRE_LIT] > 0:
            Global.change_statistic(Global.Statistic.FIRE_SIZE, -1)
            if Global.statistics[Global.Statistic.FIRE_SIZE] <= 0:
                Global.set_statistic(Global.Statistic.FIRE_LIT, 0)

