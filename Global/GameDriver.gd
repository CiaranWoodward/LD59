extends Node

# This is a singleton that drives everything. Nothing else refers to it, but it reaches into everything else.
func _ready() -> void:
    Global.statistic_changed.connect(stat_watcher)
    Global.game_started.connect(func():
        forever_game_loop())

func stat_watcher(stat, new_value, _old_value):
    if stat == Global.Statistic.HEALTH and new_value <= 0:
        Global.table.game_over()

func forever_game_loop():
    var table = Global.table
    while table.state != Table.TableState.GameOver:
        Global.statistics[Global.Statistic.ACTION_POINTS] = Global.max_statistic_values[Global.Statistic.ACTION_POINTS]
        await table.draw_cards()

        if table.state == Table.TableState.GameOver:
            return

        # Wait for the player to finish their turn
        # TODO: End turn button
        while table.state != Table.TableState.Idle || (Global.statistics[Global.Statistic.ACTION_POINTS] > 0 && table.hand.size() > 0):
            await table.state_changed
            if table.state == Table.TableState.GameOver:
                return
        
        # End the player's turn
        await table.end_turn() 

        if table.state == Table.TableState.GameOver:
            return

        # Process the fire
        if Global.statistics[Global.Statistic.FIRE_LIT] > 0:
            Global.change_statistic(Global.Statistic.FIRE_SIZE, -1)
            if Global.statistics[Global.Statistic.FIRE_SIZE] <= 0:
                Global.set_statistic(Global.Statistic.FIRE_LIT, 0)
        
        if table.state == Table.TableState.GameOver:
            return

